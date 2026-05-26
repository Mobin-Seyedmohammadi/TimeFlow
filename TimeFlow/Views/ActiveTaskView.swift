import SwiftUI

struct ActiveTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showDiscardAlert = false

    private var task: TimeFlowTask? { vm.activeTask }

    // True when elapsed time has passed the estimate, regardless of banner/warningState
    private var isActuallyOvertime: Bool {
        guard let t = task else { return false }
        return vm.elapsedMinutes >= Double(t.finalEstimateMinutes)
    }

    // True when elapsed time is past the near-limit threshold
    private var isNearLimit: Bool {
        guard let t = task else { return false }
        return vm.elapsedMinutes >= Double(t.finalEstimateMinutes) * vm.warningThreshold
    }

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

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
                                    .font(.system(size: 24, weight: .bold))
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
                                        color: .secondary
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

                            // Estimates reference card (Recognition over Recall)
                            TimeFlowCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Estimates")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 20) {
                                        estimateLabel("Your original", value: "\(task.userEstimateMinutes) min")
                                        estimateLabel("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: .tfBlue)
                                        estimateLabel("Final selected", value: "\(task.finalEstimateMinutes) min", color: Color(hex: "059669"))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            // "Continued past estimate" info card
                            // Shown based on actual elapsed time, not warningState
                            // (warningState may be .none after the banner was dismissed)
                            if vm.continuedAfterWarning && isActuallyOvertime {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.tfBlue)
                                        .font(.system(size: 14))
                                    Text("Task continued. TimeFlow will include this extra time in your future insights.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color.tfBlue.opacity(0.06))
                                .cornerRadius(10)
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
                            // Pause/Resume
                            Button(action: {
                                if vm.isTimerRunning { vm.pauseTimer() }
                                else { vm.resumeTimer() }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: vm.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                    Text(vm.isTimerRunning ? "Pause" : "Resume")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.black.opacity(0.06))
                                .foregroundColor(.tfDark)
                                .cornerRadius(14)
                            }

                            // Finish
                            Button(action: { vm.finishTask() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "flag.checkered")
                                    Text("Finish Task")
                                        .fontWeight(.semibold)
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
                // Task ended externally
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "059669"))
                    Text("Task completed!")
                        .font(.title2.bold())
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
                .foregroundColor(.secondary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDiscardAlert = true
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
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

    // Ring and elapsed label color: orange when near limit or overtime, blue otherwise.
    // Based on actual elapsed time, not warningState (banner may have been dismissed).
    private var ringColor: Color {
        isActuallyOvertime || isNearLimit ? .tfOrange : .tfBlue
    }

    // Status chip: reflects actual elapsed time so it stays correct after banner dismissal.
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
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func estimateLabel(_ label: String, value: String, color: Color = .secondary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
