import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    // Alert state for unsaved reflection prompts
    @State private var showUnsavedAlert = false
    @State private var pendingAction: PendingAction = .none

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

    private enum PendingAction {
        case none, startNewTask, viewInsights
    }

    /// True while the user has not yet tapped "Save Reflection".
    private var isUnsaved: Bool { vm.completedTaskForReflection != nil }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                if let task = vm.completedTaskForReflection ?? savedTaskSnapshot {
                    VStack(spacing: 20) {
                        // Completed header
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(Color(hex: "059669"))
                            Text("Task Complete!")
                                .font(.system(size: 28, weight: .light))
                                .tracking(0.5)
                                .foregroundColor(Color(hex: "1A1A2E"))
                            Text(task.title)
                                .font(.system(size: 17, weight: .light))
                                .foregroundColor(Color(hex: "4A4A6A"))
                            StatusChip(category: task.category)
                        }
                        .padding(.top, 16)

                        // Unsaved reminder banner — frosted glass with orange tint
                        if isUnsaved {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(Color(hex: "D97706"))
                                Text("Tap \"Save Reflection\" to add this task to your history.")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(Color(hex: "D97706"))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "D97706").opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(Color(hex: "D97706").opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                        }

                        // Time breakdown card
                        TimeFlowCard {
                            VStack(spacing: 16) {
                                Text("Time Breakdown")
                                    .font(.system(size: 15, weight: .light))
                                    .tracking(1.0)
                                    .foregroundColor(Color(hex: "8A8AAA"))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 0) {
                                    timeBlock("Your estimate", value: "\(task.userEstimateMinutes) min", color: Color(hex: "4A4A6A"))
                                    Divider().frame(height: 50)
                                    timeBlock("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: accentBlue)
                                    Divider().frame(height: 50)
                                    timeBlock("Actual time", value: "\(task.actualDurationMinutes ?? 0) min", color: Color(hex: "059669"))
                                }

                                // Visual bar comparison
                                let maxVal = max(task.userEstimateMinutes, task.aiSuggestedMinutes, task.actualDurationMinutes ?? 1)
                                VStack(spacing: 8) {
                                    barRow("Your estimate", minutes: task.userEstimateMinutes, max: maxVal, color: Color(hex: "4A4A6A"))
                                    barRow("AI suggested", minutes: task.aiSuggestedMinutes, max: maxVal, color: accentBlue)
                                    barRow("Actual", minutes: task.actualDurationMinutes ?? 0, max: maxVal, color: Color(hex: "059669"))
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Result interpretation
                        TimeFlowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: interpretationIcon(task))
                                        .foregroundColor(interpretationColor(task))
                                        .font(.system(size: 18))
                                    Text("Result")
                                        .font(.system(size: 15, weight: .light))
                                        .tracking(0.5)
                                        .foregroundColor(Color(hex: "1A1A2E"))
                                    Spacer()
                                    EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
                                }
                                Text(vm.reflectionMessage(for: task))
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(Color(hex: "1A1A2E"))
                                Text(vm.aiComparison(for: task))
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Color(hex: "4A4A6A"))
                            }
                        }
                        .padding(.horizontal, 16)

                        // Learning insight
                        TimeFlowCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(accentBlue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Learning Insight")
                                        .font(.system(size: 14, weight: .regular))
                                        .tracking(0.5)
                                        .foregroundColor(Color(hex: "1A1A2E"))
                                    Text(vm.learningInsight(for: task))
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(Color(hex: "4A4A6A"))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Full comparison card
                        TimeFlowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Full Comparison")
                                    .font(.system(size: 13, weight: .light))
                                    .tracking(1.0)
                                    .foregroundColor(Color(hex: "8A8AAA"))
                                VStack(spacing: 6) {
                                    comparisonRow("Your original estimate", minutes: task.userEstimateMinutes, color: Color(hex: "4A4A6A"))
                                    comparisonRow("AI suggested", minutes: task.aiSuggestedMinutes, color: accentBlue)
                                    comparisonRow("Final selected estimate", minutes: task.finalEstimateMinutes, color: Color(hex: "7C3AED"))
                                    comparisonRow("Actual duration", minutes: task.actualDurationMinutes ?? 0, color: Color(hex: "059669"))
                                    if let diff = task.estimationDifferenceMinutes {
                                        Divider()
                                        HStack {
                                            Text("Difference")
                                                .font(.system(size: 13, weight: .light))
                                                .foregroundColor(Color(hex: "8A8AAA"))
                                            Spacer()
                                            Text(diff >= 0 ? "+\(diff) min" : "\(diff) min")
                                                .font(.system(size: 13, weight: .regular))
                                                .tracking(0.5)
                                                .foregroundColor(abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : accentBlue))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 160)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "8A8AAA"))
                        Text("No task to reflect on.")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color(hex: "8A8AAA"))
                    }
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Snapshot once; kept alive for display during dismiss animation after saving
            if let task = vm.completedTaskForReflection {
                savedTaskSnapshot = task
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // Discard button — explicitly exits without saving
                Button {
                    vm.discardReflection()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "8A8AAA"))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                VStack(spacing: 8) {
                    // Primary: Save — the ONLY path that persists to history
                    PrimaryButton("Save Reflection", icon: "checkmark.circle.fill") {
                        vm.saveReflection()
                    }

                    // Start Another Task — prompts if unsaved
                    PrimaryButton("Start Another Task", icon: "plus.circle", style: .outline) {
                        if isUnsaved {
                            pendingAction = .startNewTask
                            showUnsavedAlert = true
                        } else {
                            launchNewTask()
                        }
                    }

                    // View Insights — prompts if unsaved
                    Button {
                        if isUnsaved {
                            pendingAction = .viewInsights
                            showUnsavedAlert = true
                        } else {
                            navigateToInsights()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 13))
                            Text("View Insights")
                                .font(.system(size: 15, weight: .light))
                                .tracking(0.5)
                        }
                        .foregroundColor(Color(hex: "8A8AAA"))
                    }
                }
            }
        }
        // ── Unsaved reflection alert ───────────────────────────────────────────
        .alert(alertTitle, isPresented: $showUnsavedAlert) {
            Button("Save and Continue") {
                vm.saveReflection()
                executePendingAction()
            }
            Button("Discard", role: .destructive) {
                vm.discardReflection()
                executePendingAction()
            }
            Button("Cancel", role: .cancel) {
                pendingAction = .none
            }
        } message: {
            Text("If you discard, this task will not be added to your history or AI model.")
        }
    }

    // MARK: - Alert helpers

    private var alertTitle: String {
        switch pendingAction {
        case .startNewTask: return "Save your reflection before starting a new task?"
        case .viewInsights: return "Save your reflection before viewing Insights?"
        case .none:         return "Save your reflection?"
        }
    }

    private func executePendingAction() {
        let action = pendingAction
        pendingAction = .none
        switch action {
        case .none: break
        case .startNewTask:
            // showReflection is already false; wait for dismiss animation then open sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                vm.startNewTask()
            }
        case .viewInsights:
            vm.selectedTab = 1      // switch to Insights tab
            // showReflection already false; cover will animate out
        }
    }

    private func launchNewTask() {
        vm.showReflection = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            vm.startNewTask()
        }
    }

    private func navigateToInsights() {
        vm.selectedTab = 1
        vm.showReflection = false
    }

    // MARK: - Snapshot for display after saving
    // After saveReflection() clears completedTaskForReflection the view briefly has no task.
    // We snapshot the task on appear so the UI doesn't flash empty during the dismiss animation.
    @State private var savedTaskSnapshot: TimeFlowTask? = nil

    // Populated once in onAppear; doesn't react to further changes so the dismiss animation
    // still has something to render after completedTaskForReflection is cleared.

    // MARK: - Helpers

    private func interpretationIcon(_ task: TimeFlowTask) -> String {
        guard let diff = task.estimationDifferenceMinutes else { return "questionmark.circle" }
        if abs(diff) <= 3 { return "checkmark.circle.fill" }
        return diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    private func interpretationColor(_ task: TimeFlowTask) -> Color {
        guard let diff = task.estimationDifferenceMinutes else { return Color(hex: "8A8AAA") }
        if abs(diff) <= 3 { return Color(hex: "059669") }
        return diff > 0 ? .tfOrange : accentBlue
    }

    private func timeBlock(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .regular))
                .tracking(0.5)
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .light))
                .tracking(0.5)
                .foregroundColor(Color(hex: "8A8AAA"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func barRow(_ label: String, minutes: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(Color(hex: "8A8AAA"))
                .frame(width: 78, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.2)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: max > 0 ? geo.size.width * (CGFloat(minutes) / CGFloat(max)) : 0, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(minutes)")
                .font(.system(size: 12, weight: .regular))
                .tracking(0.5)
                .foregroundColor(color)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func comparisonRow(_ label: String, minutes: Int, color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "4A4A6A"))
            }
            Spacer()
            Text("\(minutes) min")
                .font(.system(size: 13, weight: .regular))
                .tracking(0.5)
                .foregroundColor(color)
        }
    }
}
