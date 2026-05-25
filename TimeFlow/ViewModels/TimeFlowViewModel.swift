import SwiftUI
import Combine
import UserNotifications
import UIKit

class TimeFlowViewModel: ObservableObject {

    // MARK: - Settings
    @Published var warningThreshold: Double = 0.85
    @Published var showAIExplanation: Bool = true
    @Published var simulatedNotifications: Bool = true
    @Published var defaultCategory: TaskCategory = .study
    @Published var prototypeMode: Bool = true
    /// 1 real second = 1 simulated minute in prototype mode
    var prototypeSecondsPerSimulatedMinute: Double = 1.0

    // MARK: - Persistence Keys
    private let historyKey            = "timeflow_tasks"
    private let legacyHistoryKey      = "timeflow_completed_tasks"
    private let categoryStatsKey      = "timeflow_category_stats"
    private let predictionConfKey     = "timeflow_prediction_confidence"
    private let activeTaskKey         = "timeflow_active_task"
    private let taskStartDateKey      = "timeflow_task_start_date"
    private let elapsedMinutesKey     = "timeflow_elapsed_minutes"

    // MARK: - Data
    @Published var completedTasks: [TimeFlowTask] = []

    /// Per-category regression stats: [category.rawValue: RegressionStats]
    @Published var categoryStats: [String: RegressionStats] = [:]

    /// Preferred prediction confidence level (80, 85, 90, or 95).
    /// Saved immediately to UserDefaults via didSet.
    @Published var predictionConfidence: Int = 80 {
        didSet {
            UserDefaults.standard.set(predictionConfidence, forKey: predictionConfKey)
        }
    }

    // MARK: - Init
    init() {
        // ── Persistent data ────────────────────────────────────────────────────
        // Load completedTasks — try new key first, then legacy key
        let tasksData = UserDefaults.standard.data(forKey: historyKey)
            ?? UserDefaults.standard.data(forKey: legacyHistoryKey)
        if let data = tasksData,
           let saved = try? JSONDecoder().decode([TimeFlowTask].self, from: data) {
            completedTasks = saved
        }

        // Load categoryStats
        if let data = UserDefaults.standard.data(forKey: categoryStatsKey),
           let saved = try? JSONDecoder().decode([String: RegressionStats].self, from: data) {
            categoryStats = saved
        }

        // Load predictionConfidence (0 means key not set → default 80)
        let savedConf = UserDefaults.standard.integer(forKey: predictionConfKey)
        predictionConfidence = savedConf > 0 ? savedConf : 80

        // ── Active task recovery (survives app kills) ──────────────────────────
        if let data = UserDefaults.standard.data(forKey: activeTaskKey),
           let savedTask = try? JSONDecoder().decode(TimeFlowTask.self, from: data) {

            activeTask = savedTask
            showActiveTask = true

            let savedStartInterval = UserDefaults.standard.double(forKey: taskStartDateKey)

            if savedStartInterval > 0 {
                // Task was running when app was killed / went to background
                let anchor = Date(timeIntervalSince1970: savedStartInterval)
                taskStartDate = anchor
                let computed = Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute
                elapsedMinutes = max(0, computed)
                isTimerRunning = true

                // Restore warning flags based on how much time has passed
                restoreWarningState()

                // Kick off the tick loop after the run loop is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.startTimerTick()
                }
            } else {
                // Task was paused when app was killed
                let savedElapsed = UserDefaults.standard.double(forKey: elapsedMinutesKey)
                elapsedMinutes = max(0, savedElapsed)
                isTimerRunning = false
                restoreWarningState()
            }
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

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(completedTasks) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
        if let data = try? JSONEncoder().encode(categoryStats) {
            UserDefaults.standard.set(data, forKey: categoryStatsKey)
        }
        // predictionConfidence is saved via didSet, but belt-and-suspenders here too
        UserDefaults.standard.set(predictionConfidence, forKey: predictionConfKey)
    }

    // MARK: - Computed Insights

    var insights: [Insight] {
        let doneTasks = completedTasks.filter { $0.actualDurationMinutes != nil }
        guard !doneTasks.isEmpty else { return [] }

        var result: [Insight] = []

        // Overall pattern if 3+ tasks: avg((actual - estimate) / estimate * 100)
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

        // Per-category insights
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

        // Best category
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

    // MARK: - Active Task
    @Published var activeTask: TimeFlowTask? = nil
    @Published var elapsedMinutes: Double = 0
    @Published var isTimerRunning: Bool = false
    @Published var warningState: WarningState = .none
    @Published var continuedAfterWarning: Bool = false
    private var hasShownNearLimit = false
    private var hasShownReachedLimit = false

    /// Wall-clock anchor for elapsed time.
    /// elapsedMinutes = (Date() − taskStartDate) / prototypeSecondsPerSimulatedMinute
    /// nil when the timer is paused or stopped.
    private var taskStartDate: Date? = nil

    /// Combine subscriptions for app lifecycle notifications.
    private var foregroundObserver: AnyCancellable?
    private var backgroundObserver: AnyCancellable?

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
    /// Controls which tab is selected in MainTabView (0=Today, 1=History, 2=Insights, 3=Settings)
    @Published var selectedTab: Int = 0

    // MARK: - Timer
    private var timerCancellable: AnyCancellable?

    // MARK: - Computed

    var progressPercentage: Double {
        guard let task = activeTask, task.finalEstimateMinutes > 0 else { return 0 }
        return elapsedMinutes / Double(task.finalEstimateMinutes)
    }

    var remainingMinutes: Double {
        guard let task = activeTask else { return 0 }
        return max(Double(task.finalEstimateMinutes) - elapsedMinutes, 0)
    }

    var overtimeMinutes: Double {
        guard let task = activeTask else { return 0 }
        return max(elapsedMinutes - Double(task.finalEstimateMinutes), 0)
    }

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

    // MARK: - AI Prediction (computed)

    /// Computes a real-time prediction using current draft values and regression stats.
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
        activeTask = task
        showNewTaskSheet = false
        showEstimateReview = false
        resetTimerState()
        startTimer()
        scheduleWarningNotifications(for: task)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showActiveTask = true
        }
    }

    // MARK: - Timer

    func startTimer() {
        guard activeTask != nil else { return }
        // Anchor: now minus already-elapsed real seconds (so elapsed restarts from 0)
        taskStartDate = Date().addingTimeInterval(
            -(elapsedMinutes * prototypeSecondsPerSimulatedMinute)
        )
        isTimerRunning = true
        startTimerTick()
        saveActiveTaskState()
    }

    /// Starts (or restarts) the Combine ticker that drives UI updates.
    private func startTimerTick() {
        timerCancellable?.cancel()
        // Tick at the prototype rate (1 s/simulated-min). Wall-clock anchoring means
        // skipped ticks (background) never cause elapsed drift.
        timerCancellable = Timer.publish(
            every: prototypeSecondsPerSimulatedMinute,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in self?.tick() }
    }

    func pauseTimer() {
        if let task = activeTask { cancelWarningNotifications(taskID: task.id) }
        // Freeze elapsed at the current wall-clock value before clearing the anchor
        if let anchor = taskStartDate {
            elapsedMinutes = max(0,
                Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
        }
        taskStartDate = nil
        isTimerRunning = false
        timerCancellable?.cancel()
        activeTask?.status = .paused
        saveActiveTaskState()
    }

    func resumeTimer() {
        guard let task = activeTask else { return }
        activeTask?.status = continuedAfterWarning ? .overtime : .active
        // Restore anchor so the clock continues from the current elapsed value
        taskStartDate = Date().addingTimeInterval(
            -(elapsedMinutes * prototypeSecondsPerSimulatedMinute)
        )
        isTimerRunning = true
        startTimerTick()
        scheduleWarningNotifications(for: task)
        saveActiveTaskState()
    }

    private func tick() {
        guard isTimerRunning, let task = activeTask, let anchor = taskStartDate else { return }

        // Compute elapsed from the real wall clock — background-proof
        elapsedMinutes = max(0,
            Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)

        updateWarningState(for: task)
    }

    /// Evaluates warning thresholds and updates warningState / task status.
    private func updateWarningState(for task: TimeFlowTask) {
        let estimate       = Double(task.finalEstimateMinutes)
        let nearThreshold  = estimate * warningThreshold

        if elapsedMinutes >= estimate {
            activeTask?.status = .overtime
            if !hasShownReachedLimit && !continuedAfterWarning {
                hasShownReachedLimit = true
                warningState = .reachedLimit
            } else if continuedAfterWarning {
                warningState = .overtime
            }
        } else if elapsedMinutes >= nearThreshold {
            if !hasShownNearLimit {
                hasShownNearLimit = true
                warningState = .nearLimit
            }
        }
    }

    /// Restores warning flags when re-entering an in-progress task (after app-kill recovery).
    private func restoreWarningState() {
        guard let task = activeTask else { return }
        let estimate      = Double(task.finalEstimateMinutes)
        let nearThreshold = estimate * warningThreshold

        if elapsedMinutes >= estimate {
            hasShownNearLimit    = true
            hasShownReachedLimit = true
            activeTask?.status   = .overtime
            warningState         = .reachedLimit   // prompt the user to respond
        } else if elapsedMinutes >= nearThreshold {
            hasShownNearLimit = true
            warningState      = .nearLimit
        }
    }

    func continueTask() {
        continuedAfterWarning = true
        hasShownNearLimit = true
        hasShownReachedLimit = true
        warningState = elapsedMinutes >= Double(activeTask?.finalEstimateMinutes ?? 0) ? .overtime : .none
    }

    func finishTask() {
        timerCancellable?.cancel()
        isTimerRunning = false
        guard var task = activeTask else { return }
        cancelWarningNotifications(taskID: task.id)
        // Compute final elapsed from wall clock before clearing anchor
        if let anchor = taskStartDate {
            elapsedMinutes = max(0,
                Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
        }
        taskStartDate = nil
        task.actualDurationMinutes = max(1, Int(elapsedMinutes.rounded()))
        task.status = .completed
        task.completedAt = Date()
        completedTaskForReflection = task
        activeTask = nil
        elapsedMinutes = 0
        warningState = .none
        clearActiveTaskState()
        showActiveTask = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showReflection = true
        }
    }

    func discardActiveTask() {
        if let task = activeTask { cancelWarningNotifications(taskID: task.id) }
        timerCancellable?.cancel()
        isTimerRunning = false
        taskStartDate = nil
        activeTask = nil
        resetTimerState()
        clearActiveTaskState()
        showActiveTask = false
    }

    /// Saves the completed task to history and updates regression stats.
    /// This is the ONLY place where a task is persisted; nothing is saved on finishTask().
    func saveReflection() {
        guard let task = completedTaskForReflection else { return }

        // Update per-category regression stats (x = user estimate, y = actual duration)
        let x = Double(task.userEstimateMinutes)
        if let actualMinutes = task.actualDurationMinutes {
            let y = Double(actualMinutes)
            if x > 0 && y > 0 {
                categoryStats[task.category.rawValue, default: RegressionStats()].update(x: x, y: y)
            }
        }

        completedTasks.insert(task, at: 0)
        saveHistory()
        // Clear BEFORE setting showReflection = false so onDismiss is a no-op
        completedTaskForReflection = nil
        showReflection = false
    }

    /// Discards the pending reflection without saving anything.
    /// Safe to call even if the task was already saved (nil-guarded).
    func discardReflection() {
        guard completedTaskForReflection != nil else { return }
        completedTaskForReflection = nil
        showReflection = false
    }

    func resetPrototypeData() {
        // Cancel any running notifications before clearing state
        if let task = activeTask { cancelWarningNotifications(taskID: task.id) }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        timerCancellable?.cancel()
        isTimerRunning = false
        activeTask = nil
        resetTimerState()

        completedTasks = []
        categoryStats = [:]
        predictionConfidence = 80   // didSet saves it immediately

        // Explicitly remove all UserDefaults keys so app restores to first-launch state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: historyKey)
        defaults.removeObject(forKey: legacyHistoryKey)
        defaults.removeObject(forKey: categoryStatsKey)
        defaults.removeObject(forKey: predictionConfKey)
        defaults.removeObject(forKey: activeTaskKey)
        defaults.removeObject(forKey: taskStartDateKey)
        defaults.removeObject(forKey: elapsedMinutesKey)

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
        let aiDiff = abs(actual - task.aiSuggestedMinutes)
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

    // MARK: - Background / Foreground Handling

    /// Called when the app returns to the foreground.
    /// Recomputes elapsed from the wall-clock anchor to fix any drift caused by backgrounding.
    private func handleForeground() {
        guard isTimerRunning, let anchor = taskStartDate, activeTask != nil else { return }
        elapsedMinutes = max(0,
            Date().timeIntervalSince(anchor) / prototypeSecondsPerSimulatedMinute)
        if let task = activeTask { updateWarningState(for: task) }
    }

    /// Called when the app moves to the background.
    /// Saves the wall-clock anchor so elapsed time survives both backgrounding and app kills.
    private func handleBackground() {
        guard activeTask != nil else { return }
        saveActiveTaskState()
    }

    // MARK: - Active Task Persistence

    /// Persists the active task + timer anchor to UserDefaults so state survives app kills.
    private func saveActiveTaskState() {
        guard let task = activeTask else { clearActiveTaskState(); return }
        if let data = try? JSONEncoder().encode(task) {
            UserDefaults.standard.set(data, forKey: activeTaskKey)
        }
        if let anchor = taskStartDate {
            UserDefaults.standard.set(anchor.timeIntervalSince1970, forKey: taskStartDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: taskStartDateKey)
        }
        UserDefaults.standard.set(elapsedMinutes, forKey: elapsedMinutesKey)
    }

    /// Removes all active-task state from UserDefaults (task finished, discarded, or reset).
    private func clearActiveTaskState() {
        UserDefaults.standard.removeObject(forKey: activeTaskKey)
        UserDefaults.standard.removeObject(forKey: taskStartDateKey)
        UserDefaults.standard.removeObject(forKey: elapsedMinutesKey)
    }

    // MARK: - Notification Scheduling

    /// Schedule two local push notifications for the active task.
    /// Respects the `simulatedNotifications` toggle — if off, only in-app cards appear.
    func scheduleWarningNotifications(for task: TimeFlowTask) {
        guard simulatedNotifications else { return }

        let center = UNUserNotificationCenter.current()
        let nearID  = "timeflow-near-\(task.id.uuidString)"
        let limitID = "timeflow-limit-\(task.id.uuidString)"

        // Always cancel previous versions before rescheduling (handles resume after pause)
        center.removePendingNotificationRequests(withIdentifiers: [nearID, limitID])

        let secPerMin   = prototypeSecondsPerSimulatedMinute
        let estimateMin = Double(task.finalEstimateMinutes)

        // Seconds remaining until each threshold from NOW (based on elapsed so far)
        let toNear  = (estimateMin * warningThreshold - elapsedMinutes) * secPerMin
        let toLimit = (estimateMin - elapsedMinutes) * secPerMin

        func schedule(id: String, title: String, body: String, delay: Double) {
            guard delay > 0.5 else { return }   // skip if threshold already passed
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

    /// Cancel pending notifications for a specific task.
    func cancelWarningNotifications(taskID: UUID) {
        let ids = [
            "timeflow-near-\(taskID.uuidString)",
            "timeflow-limit-\(taskID.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func resetTimerState() {
        elapsedMinutes = 0
        warningState = .none
        continuedAfterWarning = false
        hasShownNearLimit = false
        hasShownReachedLimit = false
        taskStartDate = nil
    }
}

// MARK: - EstimateSource
enum EstimateSource {
    case user, ai, manual
}

// MARK: - AI Engine
struct AIEngine {

    /// Predict task duration using online linear regression with sufficient statistics.
    /// - Parameters:
    ///   - userEstimate: User's estimate in minutes (must be > 0)
    ///   - category: Task category
    ///   - stats: Accumulated regression stats for this category (nil = no history)
    ///   - confidencePercent: Desired prediction interval confidence (80, 85, 90, or 95)
    /// - Returns: A PredictionResult with pointEstimate >= 1, lowBound >= 1, highBound > lowBound
    static func predict(
        userEstimate: Double,
        category: TaskCategory,
        stats: RegressionStats?,
        confidencePercent: Int
    ) -> PredictionResult {

        let safeEstimate = max(1.0, userEstimate)

        // ── CASE: no data ──────────────────────────────────────────────────────
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

        // ── CASE: n == 1 ────────────────────────────────────────────────────────
        if stats.n < 2 {
            guard stats.sumX > 1e-9 else {
                // Edge: stored estimate was 0 — use default factor
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

        // ── CASE: n >= 2 — full linear regression ─────────────────────────────
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

        // Guard against degenerate case (all x-values identical)
        guard Sxx > 1e-9 else {
            // Fall back to simple ratio method
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

        // Residual variance — guard df >= 1
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

    // MARK: - Helpers

    private static func confidenceLevel(n: Int) -> PredictionConfidence {
        switch n {
        case 2:     return .low
        case 3...5: return .medium
        case 6...9: return .high
        default:    return .veryHigh
        }
    }

    /// Two-tailed t critical values (hardcoded table).
    /// df is clamped to the nearest available key; falls back to 1.282 (z ≈ 90%) if unknown.
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
