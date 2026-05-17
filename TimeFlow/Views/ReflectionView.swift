import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    var body: some View {
        ScrollView {
            if let task = vm.completedTaskForReflection {
                VStack(spacing: 20) {
                    // Completed header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(Color(hex: "059669"))
                        Text("Task Complete!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.tfDark)
                        Text(task.title)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                        StatusChip(category: task.category)
                    }
                    .padding(.top, 16)

                    // Time breakdown card
                    TimeFlowCard {
                        VStack(spacing: 16) {
                            Text("Time Breakdown")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 0) {
                                timeBlock("Your estimate", value: "\(task.userEstimateMinutes) min", color: Color.black.opacity(0.5))
                                Divider().frame(height: 50)
                                timeBlock("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: .tfBlue)
                                Divider().frame(height: 50)
                                timeBlock("Actual time", value: "\(task.actualDurationMinutes ?? 0) min", color: Color(hex: "059669"))
                            }

                            // Visual bar comparison
                            let maxVal = max(task.userEstimateMinutes, task.aiSuggestedMinutes, task.actualDurationMinutes ?? 1)
                            VStack(spacing: 8) {
                                barRow("Your estimate", minutes: task.userEstimateMinutes, max: maxVal, color: Color.black.opacity(0.35))
                                barRow("AI suggested", minutes: task.aiSuggestedMinutes, max: maxVal, color: .tfBlue)
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
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.tfDark)
                                Spacer()
                                EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
                            }
                            Text(vm.reflectionMessage(for: task))
                                .font(.system(size: 16))
                                .foregroundColor(.tfDark)
                            Text(vm.aiComparison(for: task))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
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
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.tfDark)
                                Text(vm.learningInsight(for: task))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // All estimates reference (Recognition over Recall)
                    TimeFlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Full Comparison")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            VStack(spacing: 6) {
                                comparisonRow("Your original estimate", minutes: task.userEstimateMinutes, color: Color.black.opacity(0.5))
                                comparisonRow("AI suggested", minutes: task.aiSuggestedMinutes, color: .tfBlue)
                                comparisonRow("Final selected estimate", minutes: task.finalEstimateMinutes, color: Color(hex: "7C3AED"))
                                comparisonRow("Actual duration", minutes: task.actualDurationMinutes ?? 0, color: Color(hex: "059669"))
                                if let diff = task.estimationDifferenceMinutes {
                                    Divider()
                                    HStack {
                                        Text("Difference")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(diff >= 0 ? "+\(diff) min" : "\(diff) min")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 140)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No task to reflect on.")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.tfBackground.ignoresSafeArea())
        .navigationTitle("Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                PrimaryButton("Save Reflection", icon: "checkmark.circle.fill") {
                    vm.saveReflection()
                }
                PrimaryButton("Start Another Task", icon: "plus.circle", style: .outline) {
                    vm.saveReflection()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        vm.startNewTask()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func interpretationIcon(_ task: TimeFlowTask) -> String {
        guard let diff = task.estimationDifferenceMinutes else { return "questionmark.circle" }
        if abs(diff) <= 3 { return "checkmark.circle.fill" }
        return diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    private func interpretationColor(_ task: TimeFlowTask) -> Color {
        guard let diff = task.estimationDifferenceMinutes else { return .secondary }
        if abs(diff) <= 3 { return Color(hex: "059669") }
        return diff > 0 ? .tfOrange : .tfBlue
    }

    private func timeBlock(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func barRow(_ label: String, minutes: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func comparisonRow(_ label: String, minutes: Int, color: Color) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label).font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
            Text("\(minutes) min")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
