import SwiftUI
import Combine
import UserNotifications
import UIKit

class TimeFlowViewModel: ObservableObject {

    // MARK: - Settings
    @Published var warningThreshold: Double = 0.85
    @Published var showAIExplanation: Bool = true {
        didSet { UserDefaults.standard.set(showAIExplanation, forKey: showAIExplanationKey) }
    }
    @Published var simulatedNotifications: Bool = true
    @Published var defaultCategory: TaskCategory = .study
    @Published var prototypeMode: Bool = true
    /// 1 real second = 1 simulated minute in prototype mode
    var prototypeSecondsPerSimulatedMinute: Double = 1.0

    // MARK: - Persistence Keys
    private let historyKey              = "timeflow_tasks"
    private let legacyHistoryKey        = "timeflow_completed_tasks"
    private let categoryStatsKey        = "timeflow_category_stats"
    private let predictionConfKey       = "timeflow_prediction_confidence"
    private let showAIExplanationKey    = "timeflow_show_ai_explanation"
    private let activeSessionsKey       = "timeflow_active_sessions"
    // Legacy single-task keys (used for migration only)
    private let activeTaskKey           = "timeflow_active_task"
    private let taskStartDateKey        = "timeflow_task_start_date"
    private let elapsedMinutesKey       = "timeflow_elapsed_minutes"

    // MARK: - Data
    @Published var completedTasks: [TimeFlowTask] = []
    @Published var categoryStats: [String: RegressionStats] = [:]
    @Published var predictionConfidence: Int = 80 {
        didSet { UserDefaults.standard.set(predictionConfidence, forKey: predictionConfKey) }
    }

    // MARK: - Active Sessions (multi-task)
    @Published var activeSessions: [ActiveTaskSession] = []
    /// Which session is shown in ActiveTaskView / used by compatibility shims.
    @Published var focusedSessionID: UUID? = nil

    // MARK: - Compatibility shims (existing views unchanged)
    var focusedSession: ActiveTaskSession? {
        guard let id = focusedSessionID else { return nil }
        return activeSessions.first { $0.id == id }
    }
    var activeTask: TimeFlowTask?          { focusedSession?.task }
    var elapsedMinutes: Double             { focusedSession?.elapsedMinutes ?? 0 }
    var isTimerRunning: Bool               { focusedSession?.isRunning ?? false }
    var warningState: WarningState         { focusedSession?.warningState ?? .none }
    var continuedAfterWarning: Bool        { focusedSession?.continuedAfterWarning ?? false }
    var overtimeMinutes: Double            { focusedSession?.overtimeMinutes ?? 0 }
    var remainingMinutes: Double           { focusedSession?.remainingMinutes ?? 0 }
    var progressPercentage: Double         { focusedSession?.progressFraction ?? 0 }

    // MARK: - Draft (new task creation)
    @Published var draftTitle: String = ""
    @Published var draftCategory: TaskCategory = .study
    @Published var draftUserEstimate: Int = 30
    @Published var draftNotes: String = ""
    @Published var draftAISuggestion: AISuggestion? = nil
    @Published var draftFinalEstimate: Int = 30
    @Published var draftFinalEstimateSource: EstimateSource = .user

    // MARK: - Navigation
    @Published var showNewTaskSheet: Bool = false
    @Published var showEstimateReview: Bool = false
    @Published var showActiveTask: Bool = false
    @Published var showReflection: Bool = false
    @Published var completedTaskForReflection: TimeFlowTask? = nil
    @Published var selectedTab: Int = 0

    // MARK: - Timer
    private var timerCancellable: AnyCancellable?
    private var foregroundObserver: AnyCancellable?
    private var backgroundObserver: AnyCancellable?

    // MARK: - Init
    init() {
        // ── Completed tasks ────────────────────────────────────────────────────
        let tasksData = UserDefaults.standard.data(forKey: historyKey)
            ?? UserDefaults.standard.data(forKey: legacyHistoryKey)
        if let data = tasksData,
           let saved = try? JSONDecoder().decode([TimeFlowTask].self, from: data) {
            completedTasks = saved
        }

        // ── Category stats ─────────────────────────────────────────────────────
        if let data = UserDefaults.standard.data(forKey: categoryStatsKey),
           let saved = try? JSONDecoder().decode([String: RegressionStats].self, from: data) {
            categoryStats = saved
        }

        // ── Prediction confidence ──────────────────────────────────────────────
        let savedConf = UserDefaults.standard.integer(forKey: predictionConfKey)
        predictionConfidence = savedConf > 0 ? savedConf : 80

        // ── AI explanation toggle ──────────────────────────────────────────────
        if UserDefaults.standard.object(forKey: showAIExplanationKey) != nil {
            showAIExplanation = UserDefaults.standard.bool(forKey: showAIExplanationKey)
        }

        // ── Active sessions recovery ───────────────────────────────────────────
        if let data = UserDefaults.standard.data(forKey: activeSessionsKey),
           let saved = try? JSONDecoder().decode([ActiveTaskSession].self, from: data) {

            var restoredSessions = saved
            let now = Date()
            for i in restoredSessions.indices {
                if restoredSessions[i].isRunning, let epochSec = restoredSessions[i].taskStartEpoch {
                    let anchor = Date(timeIntervalSince1970: epochSec)
                    restoredSessions[i].elapsedMinutes = max(0,
                        now.timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
                    restoreWarningStateInPlace(session: &restoredSessions[i])
                }
            }
            activeSessions = restoredSessions
            focusedSessionID = restoredSessions.first?.id

            if activeSessions.contains(where: { $0.isRunning }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.startTimerTick()
                }
            }

        } else if let data = UserDefaults.standard.data(forKey: activeTaskKey),
                  let savedTask = try? JSONDecoder().decode(TimeFlowTask.self, from: data) {
            // ── Migrate old single-task format ─────────────────────────────────
            let savedStartInterval = UserDefaults.standard.double(forKey: taskStartDateKey)
            let savedElapsed = UserDefaults.standard.double(forKey: elapsedMinutesKey)
            let isRunning = savedStartInterval > 0

            var session = ActiveTaskSession(
                task: savedTask,
                taskStartEpoch: isRunning ? savedStartInterval : nil,
                elapsedMinutes: 0,
                isRunning: isRunning,
                warningState: .none,
                continuedAfterWarning: false,
                hasShownNearLimit: false,
                hasShownReachedLimit: false,
                warningBannerDismissed: false
            )
            if isRunning, savedStartInterval > 0 {
                let anchor = Date(timeIntervalSince1970: savedStartInterval)
                session.elapsedMinutes = max(0,
                    Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
            } else {
                session.elapsedMinutes = max(0, savedElapsed)
            }
            restoreWarningStateInPlace(session: &session)
            activeSessions = [session]
            focusedSessionID = savedTask.id

            if isRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.startTimerTick()
                }
            }
            // Clean up old keys
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: activeTaskKey)
            defaults.removeObject(forKey: taskStartDateKey)
            defaults.removeObject(forKey: elapsedMinutesKey)
        }

        // ── App lifecycle observers ────────────────────────────────────────────
        foregroundObserver = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleForeground() }

        backgroundObserver = NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleBackground() }
    }

    // MARK: - Session Helpers

    private func sessionIndex(for id: UUID? = nil) -> Int? {
        let resolvedID = id ?? focusedSessionID
        guard let resolvedID else { return nil }
        return activeSessions.firstIndex { $0.id == resolvedID }
    }

    private func refreshTimerState() {
        let anyRunning = activeSessions.contains(where: { $0.isRunning })
        if anyRunning {
            if timerCancellable == nil { startTimerTick() }
        } else {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
    }

    // MARK: - Persistence

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(completedTasks) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
        if let data = try? JSONEncoder().encode(categoryStats) {
            UserDefaults.standard.set(data, forKey: categoryStatsKey)
        }
        UserDefaults.standard.set(predictionConfidence, forKey: predictionConfKey)
    }

    private func saveActiveSessionsState() {
        if activeSessions.isEmpty {
            UserDefaults.standard.removeObject(forKey: activeSessionsKey)
        } else if let data = try? JSONEncoder().encode(activeSessions) {
            UserDefaults.standard.set(data, forKey: activeSessionsKey)
        }
    }

    // MARK: - Computed Insights

    var insights: [Insight] {
        let doneTasks = completedTasks.filter { $0.actualDurationMinutes != nil }
        guard !doneTasks.isEmpty else { return [] }

        var result: [Insight] = []

        if doneTasks.count >= 3 {
            let pcts = doneTasks.compactMap { t -> Double? in
                guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                return Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100
            }
            if !pcts.isEmpty {
                let avgPct = pcts.reduce(0, +) / Double(pcts.count)
                let pctInt = Int(avgPct.rounded())
                if pctInt > 5 {
                    result.append(Insight(title: "Overall Pattern", message: "Across your \(doneTasks.count) completed tasks, you tend to underestimate by \(pctInt)% on average.", icon: "chart.line.uptrend.xyaxis", type: .pattern))
                } else if pctInt < -5 {
                    result.append(Insight(title: "Overall Pattern", message: "Across your \(doneTasks.count) completed tasks, you tend to overestimate by \(abs(pctInt))% on average.", icon: "chart.line.uptrend.xyaxis", type: .pattern))
                } else {
                    result.append(Insight(title: "Overall Accuracy", message: "Across your \(doneTasks.count) completed tasks, your estimates are very accurate — within \(abs(pctInt))% on average!", icon: "chart.line.uptrend.xyaxis", type: .accuracy))
                }
            }
        }

        var categoryGroups: [TaskCategory: [TimeFlowTask]] = [:]
        for task in doneTasks { categoryGroups[task.category, default: []].append(task) }

        for (category, tasks) in categoryGroups.sorted(by: { $0.value.count > $1.value.count }) {
            if tasks.count == 1, let task = tasks.first, let actual = task.actualDurationMinutes {
                let diff = actual - task.finalEstimateMinutes
                let body: String
                if abs(diff) <= 3 {
                    body = "Your one \(category.rawValue.lowercased()) task was estimated accurately (\(actual) min actual vs \(task.finalEstimateMinutes) min planned). Complete more tasks to see a pattern."
                } else if diff > 0 {
                    body = "Your one \(category.rawValue.lowercased()) task ran \(diff) min over (\(actual) min actual vs \(task.finalEstimateMinutes) min planned). Complete more tasks to see a pattern."
                } else {
                    body = "Your one \(category.rawValue.lowercased()) task finished \(abs(diff)) min early (\(actual) min actual vs \(task.finalEstimateMinutes) min planned). Complete more tasks to see a pattern."
                }
                result.append(Insight(title: category.rawValue, message: body, icon: category.icon, type: .pattern))
            } else if tasks.count >= 2 {
                let pcts = tasks.compactMap { t -> Double? in
                    guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                    return Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100
                }
                guard !pcts.isEmpty else { continue }
                let avgPct = pcts.reduce(0, +) / Double(pcts.count)
                let pctInt = Int(avgPct.rounded())
                let body: String; let insightType: InsightType
                if abs(pctInt) <= 5 {
                    body = "You estimate \(category.rawValue.lowercased()) tasks very accurately — within \(abs(pctInt))% on average across \(tasks.count) tasks."
                    insightType = .accuracy
                } else if pctInt > 0 {
                    body = "You underestimate \(category.rawValue.lowercased()) tasks by \(pctInt)% on average across \(tasks.count) tasks."
                    insightType = .pattern
                } else {
                    body = "You overestimate \(category.rawValue.lowercased()) tasks by \(abs(pctInt))% on average across \(tasks.count) tasks."
                    insightType = .pattern
                }
                result.append(Insight(title: category.rawValue, message: body, icon: category.icon, type: insightType))
            }
        }

        let multiTaskCategories = categoryGroups.filter { $0.value.count >= 2 }
        if multiTaskCategories.count >= 2 {
            let categoryAccuracy: [(TaskCategory, Double)] = multiTaskCategories.compactMap { cat, tasks in
                let absPcts = tasks.compactMap { t -> Double? in
                    guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                    return abs(Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100)
                }
                guard !absPcts.isEmpty else { return nil }
                return (cat, absPcts.reduce(0, +) / Double(absPcts.count))
            }
            if let best = categoryAccuracy.min(by: { $0.1 < $1.1 }) {
                let pctInt = Int(best.1.rounded())
                result.append(Insight(title: "Best Category", message: "You estimate \(best.0.rawValue.lowercased()) tasks most accurately — only \(pctInt)% off on average.", icon: best.0.icon, type: .accuracy))
            }
        }

        result.append(Insight(title: "AI Learning Note", message: "TimeFlow uses your completed tasks to build a personal regression model. The more tasks you complete, the more accurate the AI interval predictions become.", icon: "cpu", type: .aiNote))
        return result
    }

    // MARK: - Computed

    var todayCompletedCount: Int {
        completedTasks.filter { task in
            guard let d = task.completedAt else { return false }
            return Calendar.current.isDateInToday(d)
        }.count
    }

    var overallAccuracyDescription: String {
        guard !completedTasks.isEmpty else { return "Complete tasks to see your accuracy." }
        let diffs = completedTasks.compactMap { t -> Double? in
            guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
            return abs(Double(a) / Double(t.finalEstimateMinutes) - 1.0)
        }
        guard !diffs.isEmpty else { return "No data yet." }
        let avg = diffs.reduce(0, +) / Double(diffs.count)
        let pct = Int(avg * 100)
        if pct <= 5 { return "Your estimates are very accurate — within \(pct)% on average." }
        return "Your estimates are \(pct)% off on average. Keep going!"
    }

    var recentInsight: Insight? { insights.first(where: { $0.type != .aiNote }) ?? insights.first }

    // MARK: - AI Prediction

    var currentPrediction: PredictionResult? {
        guard draftUserEstimate > 0 else { return nil }
        let stats = categoryStats[draftCategory.rawValue]
        return AIEngine.predict(
            userEstimate: Double(draftUserEstimate),
            category: draftCategory,
            stats: stats,
            confidencePercent: predictionConfidence
        )
    }

    // MARK: - Task Creation

    func startNewTask() {
        draftTitle = ""
        draftCategory = defaultCategory
        draftUserEstimate = 30
        draftNotes = ""
        draftAISuggestion = nil
        draftFinalEstimate = 30
        draftFinalEstimateSource = .user
        showEstimateReview = false
        showNewTaskSheet = true
    }

    func generateAISuggestion() {
        guard let prediction = currentPrediction else { return }
        draftAISuggestion = AISuggestion(
            suggestedMinutes: prediction.pointEstimate,
            lowBound: prediction.lowBound,
            highBound: prediction.highBound,
            confidencePercent: prediction.confidencePercent,
            confidence: mapToAIConfidence(prediction.confidence),
            explanation: prediction.explanation,
            dataSource: prediction.dataSource
        )
    }

    func mapToAIConfidence(_ c: PredictionConfidence) -> AIConfidence {
        switch c {
        case .none, .veryLow:   return .low
        case .low, .medium:     return .medium
        case .high, .veryHigh:  return .high
        }
    }

    func proceedToEstimateReview() {
        generateAISuggestion()
        draftFinalEstimate = draftUserEstimate
        draftFinalEstimateSource = .user
        showEstimateReview = true
    }

    func useAISuggestion() {
        guard let s = draftAISuggestion else { return }
        draftFinalEstimate = s.suggestedMinutes
        draftFinalEstimateSource = .ai
    }

    func keepUserEstimate() {
        draftFinalEstimate = draftUserEstimate
        draftFinalEstimateSource = .user
    }

    func setManualEstimate(_ minutes: Int) {
        draftFinalEstimate = minutes
        draftFinalEstimateSource = .manual
    }

    func createAndStartTask() {
        let task = TimeFlowTask(
            id: UUID(),
            title: draftTitle.isEmpty ? "Untitled Task" : draftTitle,
            category: draftCategory,
            userEstimateMinutes: draftUserEstimate,
            aiSuggestedMinutes: draftAISuggestion?.suggestedMinutes ?? draftUserEstimate,
            finalEstimateMinutes: draftFinalEstimate,
            actualDurationMinutes: nil,
            status: .active,
            createdAt: Date(),
            completedAt: nil,
            notes: draftNotes
        )

        let session = ActiveTaskSession(
            task: task,
            taskStartEpoch: Date().timeIntervalSince1970,
            elapsedMinutes: 0,
            isRunning: true,
            warningState: .none,
            continuedAfterWarning: false,
            hasShownNearLimit: false,
            hasShownReachedLimit: false,
            warningBannerDismissed: false
        )

        activeSessions.append(session)
        focusedSessionID = task.id
        showNewTaskSheet = false
        showEstimateReview = false

        scheduleWarningNotifications(for: task, elapsedMinutes: 0)
        refreshTimerState()
        saveActiveSessionsState()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showActiveTask = true
        }
    }

    // MARK: - Timer

    private func startTimerTick() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(
            every: prototypeSecondsPerSimulatedMinute,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in self?.tick() }
    }

    func pauseTimer(sessionID: UUID? = nil) {
        guard let idx = sessionIndex(for: sessionID) else { return }
        cancelWarningNotifications(taskID: activeSessions[idx].task.id)
        if let epochSec = activeSessions[idx].taskStartEpoch {
            let anchor = Date(timeIntervalSince1970: epochSec)
            activeSessions[idx].elapsedMinutes = max(0,
                Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
        }
        activeSessions[idx].taskStartEpoch = nil
        activeSessions[idx].isRunning = false
        activeSessions[idx].task.status = .paused
        refreshTimerState()
        saveActiveSessionsState()
    }

    func resumeTimer(sessionID: UUID? = nil) {
        guard let idx = sessionIndex(for: sessionID) else { return }
        let session = activeSessions[idx]
        activeSessions[idx].task.status = session.continuedAfterWarning ? .overtime : .active
        activeSessions[idx].taskStartEpoch = Date().addingTimeInterval(
            -(session.elapsedMinutes * prototypeSecondsPerSimulatedMinute)
        ).timeIntervalSince1970
        activeSessions[idx].isRunning = true
        scheduleWarningNotifications(for: session.task, elapsedMinutes: session.elapsedMinutes)
        refreshTimerState()
        saveActiveSessionsState()
    }

    private func tick() {
        let now = Date()
        for i in activeSessions.indices {
            guard activeSessions[i].isRunning,
                  let epochSec = activeSessions[i].taskStartEpoch else { continue }
            let anchor = Date(timeIntervalSince1970: epochSec)
            activeSessions[i].elapsedMinutes = max(0,
                now.timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
            updateWarningState(forSessionAt: i)
        }
    }

    private func updateWarningState(forSessionAt i: Int) {
        let estimate      = Double(activeSessions[i].task.finalEstimateMinutes)
        let nearThreshold = estimate * warningThreshold
        let elapsed       = activeSessions[i].elapsedMinutes

        if elapsed >= estimate {
            activeSessions[i].task.status = .overtime
            if !activeSessions[i].hasShownReachedLimit && !activeSessions[i].continuedAfterWarning {
                activeSessions[i].hasShownReachedLimit = true
                activeSessions[i].warningBannerDismissed = false
                activeSessions[i].warningState = .reachedLimit
            } else if activeSessions[i].continuedAfterWarning && !activeSessions[i].warningBannerDismissed {
                activeSessions[i].warningState = .overtime
            }
            // If warningBannerDismissed == true, leave warningState as .none
        } else if elapsed >= nearThreshold {
            if !activeSessions[i].hasShownNearLimit {
                activeSessions[i].hasShownNearLimit = true
                activeSessions[i].warningBannerDismissed = false
                activeSessions[i].warningState = .nearLimit
            }
        }
    }

    /// Restores warning flags for a session when recovering from persistence.
    private func restoreWarningStateInPlace(session: inout ActiveTaskSession) {
        let estimate      = Double(session.task.finalEstimateMinutes)
        let nearThreshold = estimate * warningThreshold
        let elapsed       = session.elapsedMinutes

        if elapsed >= estimate {
            session.hasShownNearLimit    = true
            session.hasShownReachedLimit = true
            session.task.status          = .overtime
            session.warningState         = .reachedLimit
        } else if elapsed >= nearThreshold {
            session.hasShownNearLimit = true
            session.warningState      = .nearLimit
        }
    }

    func continueTask(sessionID: UUID? = nil) {
        guard let idx = sessionIndex(for: sessionID) else { return }
        activeSessions[idx].continuedAfterWarning = true
        activeSessions[idx].hasShownNearLimit = true
        activeSessions[idx].hasShownReachedLimit = true
        activeSessions[idx].warningBannerDismissed = true
        activeSessions[idx].warningState = .none
    }

    func finishTask(sessionID: UUID? = nil) {
        guard let idx = sessionIndex(for: sessionID) else { return }
        var session = activeSessions[idx]
        cancelWarningNotifications(taskID: session.task.id)

        // Final elapsed from wall clock
        if let epochSec = session.taskStartEpoch {
            let anchor = Date(timeIntervalSince1970: epochSec)
            session.elapsedMinutes = max(0,
                Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
        }
        session.task.actualDurationMinutes = max(1, Int(session.elapsedMinutes.rounded()))
        session.task.status    = .completed
        session.task.completedAt = Date()
        completedTaskForReflection = session.task

        let finishedID = session.id
        activeSessions.remove(at: idx)
        if focusedSessionID == finishedID {
            focusedSessionID = activeSessions.first?.id
        }
        refreshTimerState()
        saveActiveSessionsState()
        showActiveTask = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showReflection = true
        }
    }

    func discardActiveTask(sessionID: UUID? = nil) {
        guard let idx = sessionIndex(for: sessionID) else { return }
        let session = activeSessions[idx]
        cancelWarningNotifications(taskID: session.task.id)

        let discardedID = session.id
        activeSessions.remove(at: idx)
        if focusedSessionID == discardedID {
            focusedSessionID = activeSessions.first?.id
        }
        refreshTimerState()
        saveActiveSessionsState()
        showActiveTask = false
    }

    // MARK: - Reflection

    func saveReflection() {
        guard let task = completedTaskForReflection else { return }
        let x = Double(task.userEstimateMinutes)
        if let actualMinutes = task.actualDurationMinutes {
            let y = Double(actualMinutes)
            if x > 0 && y > 0 {
                categoryStats[task.category.rawValue, default: RegressionStats()].update(x: x, y: y)
            }
        }
        completedTasks.insert(task, at: 0)
        saveHistory()
        completedTaskForReflection = nil
        showReflection = false
    }

    func discardReflection() {
        guard completedTaskForReflection != nil else { return }
        completedTaskForReflection = nil
        showReflection = false
    }

    // MARK: - Reset

    func resetPrototypeData() {
        for session in activeSessions {
            cancelWarningNotifications(taskID: session.task.id)
        }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        timerCancellable?.cancel()
        timerCancellable = nil
        activeSessions = []
        focusedSessionID = nil

        completedTasks = []
        categoryStats = [:]
        predictionConfidence = 80

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: historyKey)
        defaults.removeObject(forKey: legacyHistoryKey)
        defaults.removeObject(forKey: categoryStatsKey)
        defaults.removeObject(forKey: predictionConfKey)
        defaults.removeObject(forKey: activeSessionsKey)
        defaults.removeObject(forKey: activeTaskKey)
        defaults.removeObject(forKey: taskStartDateKey)
        defaults.removeObject(forKey: elapsedMinutesKey)
        defaults.removeObject(forKey: showAIExplanationKey)
        showAIExplanation = true

        completedTaskForReflection = nil
        draftAISuggestion = nil
        showActiveTask = false
        showReflection = false
        showNewTaskSheet = false
        showEstimateReview = false
        selectedTab = 0
    }

    // MARK: - Reflection Helpers

    func reflectionMessage(for task: TimeFlowTask) -> String {
        guard let actual = task.actualDurationMinutes else { return "" }
        let diff = actual - task.finalEstimateMinutes
        if abs(diff) <= 3 { return "Great estimation! You were almost exactly on target." }
        if diff > 0 { return "You underestimated this task by \(diff) minute\(diff == 1 ? "" : "s")." }
        return "You overestimated this task by \(abs(diff)) minute\(abs(diff) == 1 ? "" : "s")."
    }

    func aiComparison(for task: TimeFlowTask) -> String {
        guard let actual = task.actualDurationMinutes else { return "" }
        let aiDiff   = abs(actual - task.aiSuggestedMinutes)
        let userDiff = abs(actual - task.userEstimateMinutes)
        if aiDiff < userDiff { return "The AI suggestion was closer by \(userDiff - aiDiff) min." }
        if userDiff < aiDiff { return "Your estimate was closer by \(aiDiff - userDiff) min." }
        return "Both estimates were equally close to reality."
    }

    func learningInsight(for task: TimeFlowTask) -> String {
        guard let diff = task.estimationDifferenceMinutes else { return "" }
        let pct = Int(Double(abs(diff)) / Double(max(task.finalEstimateMinutes, 1)) * 100)
        if abs(diff) <= 3 { return "You're estimating \(task.category.rawValue) tasks accurately. Keep it up!" }
        if diff > 0 { return "For \(task.category.rawValue) tasks, consider adding \(pct)% more time to future estimates." }
        return "You tend to overestimate \(task.category.rawValue) tasks. You can trim your future estimates a bit."
    }

    // MARK: - Formatting

    func formattedElapsed() -> String { formatMinutes(elapsedMinutes) }
    func formattedRemaining() -> String { formatMinutes(remainingMinutes) }
    func formattedOvertime() -> String { formatMinutes(overtimeMinutes) }

    func formatMinutes(_ minutes: Double) -> String {
        let m = Int(minutes)
        return String(format: "%d:%02d", m, 0)
    }

    func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    // MARK: - Background / Foreground

    private func handleForeground() {
        let now = Date()
        for i in activeSessions.indices {
            guard activeSessions[i].isRunning,
                  let epochSec = activeSessions[i].taskStartEpoch else { continue }
            let anchor = Date(timeIntervalSince1970: epochSec)
            activeSessions[i].elapsedMinutes = max(0,
                now.timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
            updateWarningState(forSessionAt: i)
        }
    }

    private func handleBackground() {
        guard !activeSessions.isEmpty else { return }
        saveActiveSessionsState()
    }

    // MARK: - Notification Scheduling

    func scheduleWarningNotifications(for task: TimeFlowTask, elapsedMinutes: Double = 0) {
        guard simulatedNotifications else { return }

        let center  = UNUserNotificationCenter.current()
        let nearID  = "timeflow-near-\(task.id.uuidString)"
        let limitID = "timeflow-limit-\(task.id.uuidString)"

        center.removePendingNotificationRequests(withIdentifiers: [nearID, limitID])

        let secPerMin   = prototypeSecondsPerSimulatedMinute
        let estimateMin = Double(task.finalEstimateMinutes)

        let toNear  = (estimateMin * warningThreshold - elapsedMinutes) * secPerMin
        let toLimit = (estimateMin - elapsedMinutes) * secPerMin

        func schedule(id: String, title: String, body: String, delay: Double) {
            guard delay > 0.5 else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body  = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        schedule(
            id:    nearID,
            title: "Almost at your estimate!",
            body:  "You planned \(task.finalEstimateMinutes) min for \"\(task.title)\". Are you done or still going?",
            delay: toNear
        )
        schedule(
            id:    limitID,
            title: "Time is up for \"\(task.title)\"",
            body:  "Are you finished or still working?",
            delay: toLimit
        )
    }

    func cancelWarningNotifications(taskID: UUID) {
        let ids = [
            "timeflow-near-\(taskID.uuidString)",
            "timeflow-limit-\(taskID.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - EstimateSource
enum EstimateSource {
    case user, ai, manual
}

// MARK: - AI Engine
struct AIEngine {

    static func predict(
        userEstimate: Double,
        category: TaskCategory,
        stats: RegressionStats?,
        confidencePercent: Int
    ) -> PredictionResult {

        let safeEstimate = max(1.0, userEstimate)

        guard let stats = stats, stats.n > 0 else {
            let factor = category.defaultAdjustmentFactor
            let point  = max(1.0, safeEstimate * factor)
            let low    = max(1.0, safeEstimate * factor * 0.75)
            let high   = max(low + 1.0, safeEstimate * factor * 1.35)
            return PredictionResult(
                pointEstimate:    max(1, Int(point.rounded())),
                lowBound:         max(1, Int(low.rounded())),
                highBound:        max(max(1, Int(low.rounded())) + 1, Int(high.rounded())),
                confidencePercent: confidencePercent,
                confidence:       .none,
                explanation:      "No personal history yet for \(category.rawValue) tasks. Using general patterns.",
                dataSource:       "General default"
            )
        }

        if stats.n < 2 {
            guard stats.sumX > 1e-9 else {
                let factor = category.defaultAdjustmentFactor
                let point  = max(1.0, safeEstimate * factor)
                let low    = max(1.0, point * 0.75)
                let high   = max(low + 1.0, point * 1.35)
                return PredictionResult(
                    pointEstimate:    max(1, Int(point.rounded())),
                    lowBound:         max(1, Int(low.rounded())),
                    highBound:        max(max(1, Int(low.rounded())) + 1, Int(high.rounded())),
                    confidencePercent: confidencePercent,
                    confidence:       .veryLow,
                    explanation:      "Based on 1 previous \(category.rawValue) task. Complete more tasks for a precise interval.",
                    dataSource:       "1 personal task"
                )
            }
            let ratio  = stats.sumY / stats.sumX
            let point  = max(1.0, safeEstimate * ratio)
            let low    = max(1.0, point * 0.70)
            let high   = max(low + 1.0, point * 1.40)
            let lowInt = max(1, Int(low.rounded()))
            return PredictionResult(
                pointEstimate:    max(1, Int(point.rounded())),
                lowBound:         lowInt,
                highBound:        max(lowInt + 1, Int(high.rounded())),
                confidencePercent: confidencePercent,
                confidence:       .veryLow,
                explanation:      "Based on 1 previous \(category.rawValue) task. Complete more tasks for a precise interval.",
                dataSource:       "1 personal task"
            )
        }

        let n    = stats.n
        let sumX = stats.sumX
        let sumY = stats.sumY
        let sumXX = stats.sumXX
        let sumXY = stats.sumXY
        let sumYY = stats.sumYY

        let xBar = sumX / n
        let yBar = sumY / n
        let Sxx  = sumXX - (sumX * sumX) / n
        let Sxy  = sumXY - (sumX * sumY) / n
        let Syy  = sumYY - (sumY * sumY) / n

        guard Sxx > 1e-9 else {
            let ratio  = sumX > 1e-9 ? (sumY / sumX) : category.defaultAdjustmentFactor
            let point  = max(1.0, safeEstimate * ratio)
            let low    = max(1.0, point * 0.70)
            let high   = max(low + 1.0, point * 1.40)
            let conf   = confidenceLevel(n: Int(n))
            let lowInt = max(1, Int(low.rounded()))
            return PredictionResult(
                pointEstimate:    max(1, Int(point.rounded())),
                lowBound:         lowInt,
                highBound:        max(lowInt + 1, Int(high.rounded())),
                confidencePercent: confidencePercent,
                confidence:       conf,
                explanation:      "Based on \(Int(n)) \(category.rawValue) tasks (all same estimate).",
                dataSource:       "\(Int(n)) personal \(category.rawValue) tasks"
            )
        }

        let beta1 = Sxy / Sxx
        let beta0 = yBar - beta1 * xBar
        let yHat  = max(1.0, beta0 + beta1 * safeEstimate)

        let rss    = Syy - beta1 * Sxy
        let s2raw  = rss / max(n - 2.0, 1.0)
        let s2     = s2raw.isFinite && s2raw > 0 ? s2raw : 1.0
        let s      = sqrt(max(s2, 1.0))

        let df = max(1, Int(n) - 2)
        let t  = tValue(df: df, confidence: confidencePercent)

        let leverage     = 1.0 + 1.0 / n + pow(safeEstimate - xBar, 2) / Sxx
        let marginFactor = sqrt(max(leverage, 1.0))
        let margin       = t * s * marginFactor

        let lowRaw  = max(1.0, yHat - margin)
        let highRaw = max(lowRaw + 1.0, yHat + margin)
        let lowInt  = max(1, Int(lowRaw.rounded()))
        let highInt = max(lowInt + 1, Int(highRaw.rounded()))

        let conf = confidenceLevel(n: Int(n))

        let biasPercent = Int(((yHat / max(safeEstimate, 1.0)) - 1.0) * 100)
        let biasDescription: String
        if abs(biasPercent) <= 5 {
            biasDescription = "you estimate \(category.rawValue) tasks accurately"
        } else if biasPercent > 0 {
            biasDescription = "you tend to underestimate \(category.rawValue) tasks by ~\(biasPercent)%"
        } else {
            biasDescription = "you tend to overestimate \(category.rawValue) tasks by ~\(abs(biasPercent))%"
        }

        return PredictionResult(
            pointEstimate:    max(1, Int(yHat.rounded())),
            lowBound:         lowInt,
            highBound:        highInt,
            confidencePercent: confidencePercent,
            confidence:       conf,
            explanation:      "Based on \(Int(n)) \(category.rawValue) tasks: \(biasDescription).",
            dataSource:       "\(Int(n)) personal \(category.rawValue) tasks"
        )
    }

    private static func confidenceLevel(n: Int) -> PredictionConfidence {
        switch n {
        case 2:     return .low
        case 3...5: return .medium
        case 6...9: return .high
        default:    return .veryHigh
        }
    }

    private static func tValue(df: Int, confidence: Int) -> Double {
        let table: [Int: [Int: Double]] = [
            1:  [80: 3.078, 85: 4.165, 90: 6.314,  95: 12.706],
            2:  [80: 1.886, 85: 2.282, 90: 2.920,  95: 4.303],
            3:  [80: 1.638, 85: 1.924, 90: 2.353,  95: 3.182],
            4:  [80: 1.533, 85: 1.778, 90: 2.132,  95: 2.776],
            5:  [80: 1.476, 85: 1.699, 90: 2.015,  95: 2.571],
            6:  [80: 1.440, 85: 1.650, 90: 1.943,  95: 2.447],
            7:  [80: 1.415, 85: 1.617, 90: 1.895,  95: 2.365],
            8:  [80: 1.397, 85: 1.592, 90: 1.860,  95: 2.306],
            9:  [80: 1.383, 85: 1.574, 90: 1.833,  95: 2.262],
            10: [80: 1.372, 85: 1.559, 90: 1.812,  95: 2.228],
            15: [80: 1.341, 85: 1.517, 90: 1.753,  95: 2.131],
            20: [80: 1.325, 85: 1.497, 90: 1.725,  95: 2.086],
            30: [80: 1.310, 85: 1.476, 90: 1.697,  95: 2.042],
        ]
        let keys = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30]
        let safeDf = max(df, 1)
        let closestDf = keys.last(where: { $0 <= safeDf }) ?? 30
        return table[closestDf]?[confidence] ?? 1.282
    }
}
