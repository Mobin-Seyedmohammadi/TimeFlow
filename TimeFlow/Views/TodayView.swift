import SwiftUI

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    // MARK: - Circular add button
    private var circularAddButton: some View {
        Button(action: { vm.startNewTask() }) {
            ZStack {
                // Wide outer bloom
                Circle()
                    .fill(Color(hex: "2200FF").opacity(0.22))
                    .frame(width: 270, height: 270)
                    .blur(radius: 45)
                // Inner bloom ring
                Circle()
                    .fill(Color(hex: "2200FF").opacity(0.40))
                    .frame(width: 215, height: 215)
                    .blur(radius: 22)
                // Main solid circle
                Circle()
                    .fill(Color(hex: "2200FF"))
                    .frame(width: 190, height: 190)
                // Label
                Text("New Task")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            if vm.activeSessions.isEmpty {
                // ── Empty state: just the centered button ──────────────────────
                circularAddButton

            } else {
                // ── New Task button pinned to top; cards scroll underneath ───────
                ZStack(alignment: .top) {
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
                        .padding(.horizontal, 16)
                        .padding(.top, 300)   // clears the button above
                        .padding(.bottom, 100)
                    }

                    // Button always rendered on top in Z and pinned to top in Y
                    circularAddButton
                        .padding(.top, 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
