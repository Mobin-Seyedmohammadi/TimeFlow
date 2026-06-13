import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    @State private var showUnsavedAlert = false
    @State private var pendingAction: PendingAction = .none

    private enum PendingAction {
        case none, startNewTask, viewInsights
    }

    private var isUnsaved: Bool { vm.completedTaskForReflection != nil }

    var body: some View {
        ZStack {
            AppGradients.reflection

            ScrollView {
                if let task = vm.completedTaskForReflection ?? savedTaskSnapshot {
                    VStack(spacing: 20) {
                        // Completed header
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(Color(hex: "059669"))
                            Text("Task Complete!")
                                .font(Font.dmSans(28, weight: .bold))
                                .foregroundColor(.tfDark)
                            Text(task.title)
                                .font(Font.dmSans(17))
                                .foregroundColor(.tfSecondary)
                            StatusChip(category: task.category)
                        }
                        .padding(.top, 16)

                        // Unsaved reminder banner
                        if isUnsaved {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(Color(hex: "D97706"))
                                Text("Tap \"Save Reflection\" to add this task to your history.")
                                    .font(Font.dmSans(13))
                                    .foregroundColor(Color(hex: "D97706"))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "D97706").opacity(0.10))
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                        }

                        // Time breakdown card
                        TimeFlowCard {
                            VStack(spacing: 16) {
                                Text("Time Breakdown")
                                    .font(Font.dmSans(13, weight: .medium))
                                    .foregroundColor(.tfSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 0) {
                                    timeBlock("Your estimate", value: "\(task.userEstimateMinutes) min", color: Color(hex: "C8BFDF"))
                                    Divider().frame(height: 50)
                                    timeBlock("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: Color.tfBlue.opacity(0.7))
                                    Divider().frame(height: 50)
                                    timeBlock("Actual time", value: "\(task.actualDurationMinutes ?? 0) min", color: Color(hex: "C0603A"))
                                }

                                // Visual bar comparison
                                let maxVal = max(task.userEstimateMinutes, task.aiSuggestedMinutes, task.actualDurationMinutes ?? 1)
                                VStack(spacing: 8) {
                                    barRow("Your estimate", minutes: task.userEstimateMinutes, max: maxVal, color: Color(hex: "C8BFDF"))
                                    barRow("AI suggested", minutes: task.aiSuggestedMinutes, max: maxVal, color: Color.tfBlue.opacity(0.7))
                                    barRow("Actual", minutes: task.actualDurationMinutes ?? 0, max: maxVal, color: Color(hex: "C0603A"))
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
                                        .font(Font.dmSans(17, weight: .bold))
                                        .foregroundColor(.tfDark)
                                    Spacer()
                                    EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
                                }
                                Text(vm.reflectionMessage(for: task))
                                    .font(Font.dmSans(17))
                                    .foregroundColor(.tfDark)
                                Text(vm.aiComparison(for: task))
                                    .font(Font.dmSans(15))
                                    .foregroundColor(.tfSecondary)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Learning insight
                        TimeFlowCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.tfBlue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Learning Insight")
                                        .font(Font.dmSans(17, weight: .bold))
                                        .foregroundColor(.tfDark)
                                    Text(vm.learningInsight(for: task))
                                        .font(Font.dmSans(15))
                                        .foregroundColor(.tfSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Full comparison card
                        TimeFlowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("FULL COMPARISON")
                                    .font(Font.dmSans(13, weight: .medium))
                                    .foregroundColor(.tfSecondary)
                                    .kerning(0.5)
                                VStack(spacing: 6) {
                                    comparisonRow("Your original estimate", minutes: task.userEstimateMinutes, color: Color(hex: "C8BFDF"))
                                    comparisonRow("AI suggested", minutes: task.aiSuggestedMinutes, color: Color.tfBlue.opacity(0.7))
                                    comparisonRow("Final selected estimate", minutes: task.finalEstimateMinutes, color: Color(hex: "7C3AED"))
                                    comparisonRow("Actual duration", minutes: task.actualDurationMinutes ?? 0, color: Color(hex: "C0603A"))
                                    if let diff = task.estimationDifferenceMinutes {
                                        Divider()
                                        HStack {
                                            Text("Difference")
                                                .font(Font.dmSans(13))
                                                .foregroundColor(.tfSecondary)
                                            Spacer()
                                            Text(diff >= 0 ? "+\(diff) min" : "\(diff) min")
                                                .font(Font.dmSans(13, weight: .bold))
                                                .foregroundColor(abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue))
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
                            .foregroundColor(.tfSecondary)
                        Text("No task to reflect on.")
                            .font(Font.dmSans(17))
                            .foregroundColor(.tfSecondary)
                    }
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let task = vm.completedTaskForReflection {
                savedTaskSnapshot = task
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    vm.discardReflection()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tfSecondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                VStack(spacing: 8) {
                    // Primary: Save
                    Button(action: { vm.saveReflection() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Reflection")
                                .font(Font.dmSans(17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.tfBlue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }

                    // Start Another Task
                    Button(action: {
                        if isUnsaved {
                            pendingAction = .startNewTask
                            showUnsavedAlert = true
                        } else {
                            launchNewTask()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                            Text("Start Another Task")
                                .font(Font.dmSans(17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.tfDark)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }

                    // View Insights
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
                                .font(Font.dmSans(15, weight: .medium))
                        }
                        .foregroundColor(.tfSecondary)
                    }
                }
            }
        }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                vm.startNewTask()
            }
        case .viewInsights:
            vm.selectedTab = 1
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

    @State private var savedTaskSnapshot: TimeFlowTask? = nil

    // MARK: - Helpers

    private func interpretationIcon(_ task: TimeFlowTask) -> String {
        guard let diff = task.estimationDifferenceMinutes else { return "questionmark.circle" }
        if abs(diff) <= 3 { return "checkmark.circle.fill" }
        return diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    private func interpretationColor(_ task: TimeFlowTask) -> Color {
        guard let diff = task.estimationDifferenceMinutes else { return .tfSecondary }
        if abs(diff) <= 3 { return Color(hex: "059669") }
        return diff > 0 ? .tfOrange : .tfBlue
    }

    private func timeBlock(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Font.dmSans(17, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(Font.dmSans(11))
                .foregroundColor(.tfSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func barRow(_ label: String, minutes: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(Font.dmSans(11))
                .foregroundColor(.tfSecondary)
                .frame(width: 78, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.06)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: max > 0 ? geo.size.width * (CGFloat(minutes) / CGFloat(max)) : 0, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(minutes)")
                .font(Font.dmSans(12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func comparisonRow(_ label: String, minutes: Int, color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(Font.dmSans(13))
                    .foregroundColor(.tfSecondary)
            }
            Spacer()
            Text("\(minutes) min")
                .font(Font.dmSans(13, weight: .medium))
                .foregroundColor(color)
        }
    }
}
