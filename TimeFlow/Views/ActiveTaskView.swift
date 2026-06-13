import SwiftUI

struct ActiveTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showDiscardAlert = false

    private var task: TimeFlowTask? { vm.activeTask }

    private var isActuallyOvertime: Bool {
        guard let t = task else { return false }
        return vm.elapsedMinutes >= Double(t.finalEstimateMinutes)
    }

    private var isNearLimit: Bool {
        guard let t = task else { return false }
        return vm.elapsedMinutes >= Double(t.finalEstimateMinutes) * vm.warningThreshold
    }

    var body: some View {
        ZStack {
            AppGradients.activeTask

            if let task = task {
                VStack(spacing: 0) {

                    ScrollView {
                        VStack(spacing: 20) {
                            // Task header
                            VStack(spacing: 10) {
                                HStack {
                                    StatusChip(category: task.category)
                                    Spacer()
                                    statusChip
                                }

                                Text(task.title)
                                    .font(Font.dmSans(24, weight: .bold))
                                    .foregroundColor(.tfDark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Progress ring
                            ProgressTimerView(
                                elapsedMinutes: vm.elapsedMinutes,
                                estimateMinutes: task.finalEstimateMinutes,
                                isRunning: vm.isTimerRunning,
                                warningState: vm.warningState
                            )
                            .padding(.vertical, 8)

                            // Time stats
                            TimeFlowCard {
                                HStack(spacing: 0) {
                                    timeStatColumn(
                                        label: "Elapsed",
                                        value: vm.formattedElapsed(),
                                        color: ringColor
                                    )
                                    Divider().frame(height: 44)
                                    timeStatColumn(
                                        label: "Estimated",
                                        value: "\(task.finalEstimateMinutes):00",
                                        color: .tfSecondary
                                    )
                                    Divider().frame(height: 44)
                                    if isActuallyOvertime {
                                        timeStatColumn(
                                            label: "Extra",
                                            value: "+\(Int(vm.overtimeMinutes)) min",
                                            color: .tfOrange
                                        )
                                    } else {
                                        timeStatColumn(
                                            label: "Remaining",
                                            value: vm.formattedRemaining(),
                                            color: isNearLimit ? .tfOrange : .tfBlue
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            // Estimates reference card
                            TimeFlowCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Estimates")
                                        .font(Font.dmSans(13, weight: .medium))
                                        .foregroundColor(.tfSecondary)
                                    HStack(spacing: 20) {
                                        estimateLabel("Your original", value: "\(task.userEstimateMinutes) min")
                                        estimateLabel("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: .tfBlue)
                                        estimateLabel("Final selected", value: "\(task.finalEstimateMinutes) min", color: Color(hex: "059669"))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            if vm.continuedAfterWarning && isActuallyOvertime {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.tfBlue)
                                        .font(.system(size: 14))
                                    Text("Task continued. TimeFlow will include this extra time in your future insights.")
                                        .font(Font.dmSans(13))
                                        .foregroundColor(.tfSecondary)
                                }
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                            }

                            Spacer(minLength: 120)
                        }
                    }
                }

                // Bottom controls
                VStack(spacing: 0) {
                    Spacer()
                    BottomActionBar {
                        HStack(spacing: 10) {
                            // Pause/Resume (glass style)
                            Button(action: {
                                if vm.isTimerRunning { vm.pauseTimer() }
                                else { vm.resumeTimer() }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: vm.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                    Text(vm.isTimerRunning ? "Pause" : "Resume")
                                        .font(Font.dmSans(17, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.tfDark)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                                )
                            }

                            // Finish
                            Button(action: { vm.finishTask() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "flag.checkered")
                                    Text("Finish Task")
                                        .font(Font.dmSans(17, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.tfBlue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(Color(hex: "059669"))
                    Text("Task completed!")
                        .font(Font.dmSans(22, weight: .bold))
                        .foregroundColor(.tfDark)
                }
            }
        }
        .navigationTitle("Active Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    vm.showActiveTask = false
                }
                .font(Font.dmSans(17))
                .foregroundColor(.tfSecondary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDiscardAlert = true
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.tfSecondary)
                }
            }
        }
        .alert("Discard Task?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) { vm.discardActiveTask() }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("Your progress will be lost and the task will not be saved.")
        }
    }

    private var ringColor: Color {
        isActuallyOvertime || isNearLimit ? .tfOrange : .tfBlue
    }

    private var statusChip: some View {
        let (label, icon, color): (String, String, Color) = {
            if !vm.isTimerRunning {
                return ("Paused", "pause.circle.fill", Color(hex: "D97706"))
            }
            if isActuallyOvertime {
                return ("Overtime", "clock.badge.exclamationmark.fill", .tfOrange)
            }
            if isNearLimit {
                return ("Near Limit", "exclamationmark.triangle.fill", .tfOrange)
            }
            return ("Active", "timer", .tfBlue)
        }()
        return StatusChip(label, icon: icon, color: color)
    }

    private func timeStatColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Font.dmSans(18, weight: .bold))
                .monospacedDigit()
                .foregroundColor(color)
            Text(label)
                .font(Font.dmSans(11))
                .foregroundColor(.tfSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func estimateLabel(_ label: String, value: String, color: Color = .tfSecondary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Font.dmSans(11))
                .foregroundColor(.tfSecondary)
            Text(value)
                .font(Font.dmSans(14, weight: .medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
