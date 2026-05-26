import SwiftUI

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Header ─────────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.tfDark)
                    Text("Improve your time estimates one task at a time.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // ── Summary card ───────────────────────────────────────────────
                TimeFlowCard {
                    HStack(spacing: 0) {
                        statColumn(
                            value: "\(vm.todayCompletedCount)",
                            label: "Completed Today",
                            icon: "checkmark.circle.fill",
                            color: Color(hex: "059669")
                        )
                        Divider().frame(height: 50)
                        statColumn(
                            value: "\(vm.activeSessions.count)",
                            label: "Active Tasks",
                            icon: "timer",
                            color: .tfBlue
                        )
                        Divider().frame(height: 50)
                        statColumn(
                            value: "\(vm.completedTasks.count)",
                            label: "Total Tasks",
                            icon: "list.bullet",
                            color: Color(hex: "6B7280")
                        )
                    }
                }
                .padding(.horizontal, 16)

                // ── Accuracy card ──────────────────────────────────────────────
                SectionCard(title: "Estimation Accuracy", icon: "chart.line.uptrend.xyaxis") {
                    Text(vm.overallAccuracyDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)

                // ── Active tasks list ──────────────────────────────────────────
                if !vm.activeSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(vm.activeSessions.count == 1 ? "Active Task" : "Active Tasks")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            if vm.activeSessions.count > 1 {
                                Text("\(vm.activeSessions.count)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.tfBlue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.tfBlue.opacity(0.10))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 16)

                        ForEach(vm.activeSessions) { session in
                            StateAwareTaskCard(
                                task: session.task,
                                elapsedMinutes: session.elapsedMinutes,
                                isRunning: session.isRunning,
                                warningState: session.warningState,
                                onOpen: {
                                    vm.focusedSessionID = session.id
                                    vm.showActiveTask = true
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                } else {
                    // Empty state
                    TimeFlowCard {
                        VStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 36))
                                .foregroundColor(.tfBlue.opacity(0.5))
                            Text("No active tasks yet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.tfDark)
                            Text("Start a task and TimeFlow will help you compare your estimate with reality.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 16)
                }

                // ── Start New Task button (always visible) ─────────────────────
                PrimaryButton("Start New Task", icon: "plus.circle.fill") {
                    vm.startNewTask()
                }
                .padding(.horizontal, 16)

                // ── Recent insight ─────────────────────────────────────────────
                if let insight = vm.recentInsight {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Insight")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        TimeFlowCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: insight.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.tfBlue)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(insight.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.tfDark)
                                    Text(insight.message)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // ── Prototype mode note ────────────────────────────────────────
                if vm.prototypeMode {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                        Text("Prototype timer: 1 sec = 1 simulated minute")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.tfBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { vm.startNewTask() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.tfBlue)
                }
            }
        }
    }

    private func statColumn(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.tfDark)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
