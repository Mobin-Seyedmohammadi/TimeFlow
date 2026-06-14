import SwiftUI

struct ActiveTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showDiscardAlert = false

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

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
            AuroraBackground()

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
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(Color(hex: "1A1A2E"))
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
                                        color: Color(hex: "8A8AAA")
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
                                            color: isNearLimit ? .tfOrange : accentBlue
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            // Estimates reference card (Recognition over Recall)
                            TimeFlowCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Estimates")
                                        .font(.system(size: 13, weight: .light))
                                        .tracking(1.0)
                                        .foregroundColor(Color(hex: "8A8AAA"))
                                    HStack(spacing: 20) {
                                        estimateLabel("Your original", value: "\(task.userEstimateMinutes) min")
                                        estimateLabel("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: accentBlue)
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
                                        .foregroundColor(accentBlue)
                                        .font(.system(size: 14))
                                    Text("Task continued. TimeFlow will include this extra time in your future insights.")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(Color(hex: "4A4A6A"))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(accentBlue.opacity(0.06))
                                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(accentBlue.opacity(0.2), lineWidth: 0.5))
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
                            // Pause/Resume — frosted glass secondary
                            Button(action: {
                                if vm.isTimerRunning { vm.pauseTimer() }
                                else { vm.resumeTimer() }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: vm.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                    Text(vm.isTimerRunning ? "Pause" : "Resume")
                                        .fontWeight(.regular)
                                        .tracking(0.5)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(.ultraThinMaterial)
                                .foregroundColor(Color(hex: "4A4A6A"))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5))
                            }

                            // Finish — primary blue with glow
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(accentBlue.opacity(0.4))
                                    .frame(height: 70)
                                    .blur(radius: 18)

                                Button(action: { vm.finishTask() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "flag.checkered")
                                        Text("Finish Task")
                                            .fontWeight(.regular)
                                            .tracking(0.5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(accentBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
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
                        .font(.system(size: 20, weight: .light))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "1A1A2E"))
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
                .foregroundColor(Color(hex: "8A8AAA"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDiscardAlert = true
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(Color(hex: "8A8AAA"))
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
        isActuallyOvertime || isNearLimit ? .tfOrange : accentBlue
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
            return ("Active", "timer", accentBlue)
        }()
        return StatusChip(label, icon: icon, color: color)
    }

    private func timeStatColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .light))
                .tracking(0.5)
                .foregroundColor(Color(hex: "8A8AAA"))
        }
        .frame(maxWidth: .infinity)
    }

    private func estimateLabel(_ label: String, value: String, color: Color = Color(hex: "8A8AAA")) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .light))
                .tracking(0.5)
                .foregroundColor(Color(hex: "8A8AAA"))
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .tracking(0.5)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
