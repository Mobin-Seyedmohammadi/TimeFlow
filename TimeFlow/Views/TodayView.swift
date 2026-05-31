import SwiftUI

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    // MARK: - Circular add button
    private var circularAddButton: some View {
        Button(action: { vm.startNewTask() }) {
            ZStack {
                Circle()
                    .fill(Color.tfBlue)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.tfBlue.opacity(0.38), radius: 16, x: 0, y: 7)
                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

            if vm.activeSessions.isEmpty {
                // ── Empty state: just the centered button ──────────────────────
                circularAddButton

            } else {
                // ── Active tasks + floating add button ─────────────────────────
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 14) {
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
                        }
                        .padding(16)
                        .padding(.top, 8)
                        .padding(.bottom, 120) // clear space above FAB
                    }

                    circularAddButton
                        .padding(.bottom, 32)
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
