import SwiftUI

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

            if vm.activeSessions.isEmpty {
                // ── Empty state: centered button only ─────────────────────────
                PrimaryButton("Start New Task", icon: "plus.circle.fill") {
                    vm.startNewTask()
                }
                .padding(.horizontal, 32)

            } else {
                // ── Active tasks + start button ────────────────────────────────
                ScrollView {
                    VStack(spacing: 16) {
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
                        }

                        PrimaryButton("Start New Task", icon: "plus.circle.fill") {
                            vm.startNewTask()
                        }
                    }
                    .padding(16)
                    .padding(.top, 8)
                }
            }
        }
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
}
