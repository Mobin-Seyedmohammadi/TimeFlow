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

    // MARK: - Data
    @Published var completedTasks: [TimeFlowTask] = MockData.completedTasks
    @Published var insights: [Insight] = MockData.insights

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

    var recentInsight: Insight? { insights.first }

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
        completedTaskForReflection = nil
        showReflection = false
    }

    func resetPrototypeData() {
        timerCancellable?.cancel()
        isTimerRunning = false
        activeTask = nil
        resetTimerState()
        completedTasks = MockData.completedTasks
        insights = MockData.insights
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
    ) -> AISuggestion {
        let factor = category.aiAdjustmentFactor
        let suggested = max(1, Int(Double(userEstimate) * factor))

        let categoryHistory = history.filter { $0.category == category }
        let confidence: AIConfidence = categoryHistory.count >= 3 ? .high : categoryHistory.count >= 1 ? .medium : .low

        let pct = Int((factor - 1.0) * 100)
        let explanation = explanationFor(category: category, pct: pct, confidence: confidence)

        return AISuggestion(suggestedMinutes: suggested, confidence: confidence, explanation: explanation)
    }

    private static func explanationFor(category: TaskCategory, pct: Int, confidence: AIConfidence) -> String {
        switch category {
        case .study:
            return "Based on similar study tasks, you often need around \(pct)% more time than your first estimate. Study sessions tend to involve deeper thinking and unexpected distractions."
        case .transportation:
            return "Transportation tasks are unpredictable. Based on your history, commutes typically take \(pct)% longer than expected due to traffic and delays."
        case .grocery:
            return "Grocery trips usually take \(pct)% longer than planned. Browsing, queues, and forgotten items add up quickly."
        case .workOrganization:
            return "Organizing work or notes typically takes \(pct)% more than planned. It's easy to underestimate the details and decisions involved."
        case .exercise:
            return "Your exercise estimates are quite accurate. TimeFlow suggests only a small \(pct)% buffer for warm-up, cool-down, and any unexpected delays."
        case .home:
            return "Home tasks often take \(pct)% more than expected. Small interruptions and discovering extra steps add up."
        case .other:
            return "TimeFlow suggests adding \(pct)% extra time as a general buffer. Adjust based on your own experience with this type of task."
        }
    }
}
