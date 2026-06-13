import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    /// First session that needs a warning banner (highest priority).
    private var alertingSession: ActiveTaskSession? {
        vm.activeSessions.first(where: { $0.warningState != .none })
    }

    var body: some View {
        ZStack(alignment: .top) {

            // ── Main tab content ───────────────────────────────────────────────
            TabView(selection: $vm.selectedTab) {
                NavigationStack {
                    TodayView()
                }
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)

                NavigationStack {
                    InsightsView()
                }
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
            }
            .accentColor(.tfBlue)

            // New task sheet at root level
            .sheet(isPresented: $vm.showNewTaskSheet) {
                NavigationStack {
                    NewTaskView()
                }
                .environmentObject(vm)
                .presentationDetents([.large])
            }

            // Full-screen cover for the focused active task timer
            .fullScreenCover(isPresented: $vm.showActiveTask) {
                ZStack(alignment: .top) {
                    NavigationStack {
                        ActiveTaskView()
                    }
                    .environmentObject(vm)

                    // Banner inside the cover — warns about the FOCUSED session
                    if let session = vm.focusedSession, session.warningState != .none {
                        WarningBanner(
                            state: session.warningState,
                            taskName: session.task.title,
                            estimateMinutes: session.task.finalEstimateMinutes,
                            elapsedMinutes: session.elapsedMinutes,
                            onFinish: { vm.finishTask(sessionID: session.id) },
                            onContinue: { vm.continueTask(sessionID: session.id) }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: session.warningState)
                        .zIndex(200)
                    }
                }
            }

            // Full-screen cover for reflection
            .fullScreenCover(isPresented: $vm.showReflection, onDismiss: {
                vm.discardReflection()
            }) {
                NavigationStack {
                    ReflectionView()
                }
                .environmentObject(vm)
            }

            // ── Global warning banner — visible on any tab when timer is not open ──
            // Shows for whichever session currently has a warning state.
            if let session = alertingSession, !vm.showActiveTask {
                WarningBanner(
                    state: session.warningState,
                    taskName: session.task.title,
                    estimateMinutes: session.task.finalEstimateMinutes,
                    elapsedMinutes: session.elapsedMinutes,
                    onFinish: { vm.finishTask(sessionID: session.id) },
                    onContinue: { vm.continueTask(sessionID: session.id) }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: session.warningState)
                .zIndex(100)
            }
        }
    }
}
