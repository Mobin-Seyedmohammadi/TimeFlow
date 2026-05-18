import SwiftUI
import Combine

class TimeFlowViewModel: ObservableObject {

    // MARK: - Settings
    @Published var warningThreshold: Double = 0.85
    @Published var showAIExplanation: Bool = true
    @Published var simulatedNotifications: Bool = true
    @Published var defaultCategory: TaskCategory = .study
    @Published var prototypeMode: Bool = true
    /// 1 real second = 1 simulated minute in prototype mode
    var prototypeSecondsPerSimulatedMinute: Double = 1.0

    // MARK: - Persistence
    private let historyKey = "timeflow_completed_tasks"

    // MARK: - Data
    @Published var completedTasks: [TimeFlowTask] = []

    // MARK: - Init

    init() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([TimeFlowTask].self, from: data) {
            completedTasks = saved
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(completedTasks) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    // MARK: - Computed Insights

    var insights: [Insight] {
        let doneTasks = completedTasks.filter { $0.actualDurationMinutes != nil }
        guard !doneTasks.isEmpty else { return [] }

        var result: [Insight] = []

        // Overall pattern if 3+ tasks
        if doneTasks.count >= 3 {
            let errors = doneTasks.compactMap { t -> Double? in
                guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                return (Double(a) / Double(t.finalEstimateMinutes) - 1.0) * 100
            }
            if !errors.isEmpty {
                let avg = errors.reduce(0, +) / Double(errors.count)
                let pct = Int(avg.rounded())
                if pct > 5 {
                    result.append(Insight(title: "Overall Pattern", message: "Across your \(doneTasks.count) completed tasks, you tend to underestimate by \(pct)% on average.", icon: "chart.line.uptrend.xyaxis", type: .pattern))
                } else if pct < -5 {
                    result.append(Insight(title: "Overall Pattern", message: "Across your \(doneTasks.count) completed tasks, you tend to overestimate by \(abs(pct))% on average.", icon: "chart.line.uptrend.xyaxis", type: .pattern))
                } else {
                    result.append(Insight(title: "Overall Accuracy", message: "Across your \(doneTasks.count) completed tasks, your estimates are very accurate — within \(abs(pct))% on average!", icon: "chart.line.uptrend.xyaxis", type: .accuracy))
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
                    body = "Your one \(category.rawValue.lowercased()) task was estimated accurately (\(actual) min actual). Complete more tasks to see a pattern."
                } else if diff > 0 {
                    body = "Your one \(category.rawValue.lowercased()) task ran \(diff) min over (\(actual) min actual vs \(task.finalEstimateMinutes) min planned). Complete more tasks to see a pattern."
                } else {
                    body = "Your one \(category.rawValue.lowercased()) task finished \(abs(diff)) min early (\(actual) min actual vs \(task.finalEstimateMinutes) min planned). Complete more tasks to see a pattern."
                }
                result.append(Insight(title: category.rawValue, message: body, icon: category.icon, type: .pattern))
            } else if tasks.count >= 2 {
                let errors = tasks.compactMap { t -> Double? in
                    guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                    return (Double(a) / Double(t.finalEstimateMinutes) - 1.0) * 100
                }
                guard !errors.isEmpty else { continue }
                // Recency-weighted average (index 0 = newest, gets highest weight)
                let n = Double(errors.count)
                var weightedSum = 0.0; var totalWeight = 0.0
                for (i, e) in errors.enumerated() {
                    let w = n - Double(i); weightedSum += e * w; totalWeight += w
                }
                let pct = Int((weightedSum / totalWeight).rounded())
                let body: String; let type: InsightType
                if abs(pct) <= 5 {
                    body = "You estimate \(category.rawValue.lowercased()) tasks very accurately — only \(abs(pct))% off on average across \(tasks.count) tasks."
                    type = .accuracy
                } else if pct > 0 {
                    body = "You underestimate \(category.rawValue.lowercased()) tasks by \(pct)% on average across \(tasks.count) tasks. Consider adding a \(pct)% buffer."
                    type = .pattern
                } else {
                    body = "You overestimate \(category.rawValue.lowercased()) tasks by \(abs(pct))% on average across \(tasks.count) tasks. You can trim your estimates a bit."
                    type = .pattern
                }
                result.append(Insight(title: category.rawValue, message: body, icon: category.icon, type: type))
            }
        }

        // Best category badge when multiple categories have 2+ tasks
        let multiTaskCategories = categoryGroups.filter { $0.value.count >= 2 }
        if multiTaskCategories.count >= 2 {
            let categoryAccuracy: [(TaskCategory, Double)] = multiTaskCategories.compactMap { cat, tasks in
                let abs_errors = tasks.compactMap { t -> Double? in
                    guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                    return abs(Double(a) / Double(t.finalEstimateMinutes) - 1.0)
                }
                guard !abs_errors.isEmpty else { return nil }
                return (cat, abs_errors.reduce(0, +) / Double(abs_errors.count))
            }
            if let best = categoryAccuracy.min(by: { $0.1 < $1.1 }) {
                let pct = Int((best.1 * 100).rounded())
                result.append(Insight(title: "Best Category", message: "You estimate \(best.0.rawValue.lowercased()) tasks most accurately — only \(pct)% off on average.", icon: best.0.icon, type: .accuracy))
            }
        }

        result.append(Insight(title: "AI Learning Note", message: "TimeFlow uses your completed tasks to adjust suggestions. The more tasks you complete, the more personalized the AI becomes.", icon: "cpu", type: .aiNote))
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
        draftAISuggestion = AIEngine.generateSuggestion(
            category: draftCategory,
            userEstimate: draftUserEstimate,
            history: completedTasks
        )
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showActiveTask = true
        }
    }

    // MARK: - Timer

    func startTimer() {
        guard activeTask != nil else { return }
        isTimerRunning = true
        timerCancellable = Timer.publish(
            every: prototypeSecondsPerSimulatedMinute,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in self?.tick() }
    }

    func pauseTimer() {
        isTimerRunning = false
        timerCancellable?.cancel()
        activeTask?.status = .paused
    }

    func resumeTimer() {
        guard activeTask != nil else { return }
        activeTask?.status = continuedAfterWarning ? .overtime : .active
        isTimerRunning = true
        timerCancellable = Timer.publish(
            every: prototypeSecondsPerSimulatedMinute,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard isTimerRunning, let task = activeTask else { return }
        elapsedMinutes += 1

        let estimate = Double(task.finalEstimateMinutes)
        let nearThreshold = estimate * warningThreshold

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
        task.actualDurationMinutes = max(1, Int(elapsedMinutes.rounded()))
        task.status = .completed
        task.completedAt = Date()
        completedTaskForReflection = task
        activeTask = nil
        elapsedMinutes = 0
        warningState = .none
        showActiveTask = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showReflection = true
        }
    }

    func discardActiveTask() {
        timerCancellable?.cancel()
        isTimerRunning = false
        activeTask = nil
        resetTimerState()
        showActiveTask = false
    }

    func saveReflection() {
        guard let task = completedTaskForReflection else { return }
        completedTasks.insert(task, at: 0)
        saveHistory()
        completedTaskForReflection = nil
        showReflection = false
    }

    func resetPrototypeData() {
        timerCancellable?.cancel()
        isTimerRunning = false
        activeTask = nil
        resetTimerState()
        completedTasks = []
        saveHistory()
        completedTaskForReflection = nil
        showActiveTask = false
        showReflection = false
        showNewTaskSheet = false
        showEstimateReview = false
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
        let pct = Int(Double(abs(diff)) / Double(task.finalEstimateMinutes) * 100)
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

    // MARK: - Private

    private func resetTimerState() {
        elapsedMinutes = 0
        warningState = .none
        continuedAfterWarning = false
        hasShownNearLimit = false
        hasShownReachedLimit = false
    }
}

// MARK: - EstimateSource
enum EstimateSource {
    case user, ai, manual
}

// MARK: - AI Engine
struct AIEngine {
    static func generateSuggestion(
        category: TaskCategory,
        userEstimate: Int,
        history: [TimeFlowTask]
    ) -> AISuggestion? {
        let categoryHistory = history.filter { $0.category == category && $0.actualDurationMinutes != nil }

        // No data for this category — stay silent rather than make unfounded claims
        guard !categoryHistory.isEmpty else { return nil }

        let factor: Double
        let isPersonalized: Bool

        if categoryHistory.count >= 2 {
            let ratios = categoryHistory.compactMap { t -> Double? in
                guard let a = t.actualDurationMinutes, t.userEstimateMinutes > 0 else { return nil }
                return Double(a) / Double(t.userEstimateMinutes)
            }
            guard !ratios.isEmpty else { return nil }
            factor = ratios.reduce(0, +) / Double(ratios.count)
            isPersonalized = true
        } else {
            // 1 task: use it directly (no blending with hardcoded defaults)
            guard let task = categoryHistory.first,
                  let actual = task.actualDurationMinutes,
                  task.userEstimateMinutes > 0 else { return nil }
            factor = Double(actual) / Double(task.userEstimateMinutes)
            isPersonalized = true
        }

        let suggested = max(1, Int(Double(userEstimate) * factor))
        let confidence: AIConfidence = categoryHistory.count >= 3 ? .high : categoryHistory.count >= 1 ? .medium : .low
        let pct = Int((factor - 1.0) * 100)
        let explanation = explanationFor(category: category, pct: pct, taskCount: categoryHistory.count)

        return AISuggestion(suggestedMinutes: suggested, confidence: confidence, explanation: explanation)
    }

    private static func explanationFor(category: TaskCategory, pct: Int, taskCount: Int) -> String {
        let taskWord = taskCount == 1 ? "task" : "tasks"
        if pct > 0 {
            return "Based on your \(taskCount) past \(category.rawValue.lowercased()) \(taskWord), you typically take \(pct)% longer than your first estimate. This suggestion adjusts for your personal pattern."
        } else if pct < 0 {
            return "Based on your \(taskCount) past \(category.rawValue.lowercased()) \(taskWord), you tend to finish \(abs(pct))% faster than your estimate. This suggestion trims your estimate slightly."
        } else {
            return "Based on your \(taskCount) past \(category.rawValue.lowercased()) \(taskWord), your estimates are accurate. This suggestion matches your original estimate."
        }
    }
}
