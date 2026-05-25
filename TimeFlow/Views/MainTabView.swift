import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

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
                    HistoryView()
                }
                .tabItem { Label("History", systemImage: "list.bullet.rectangle") }
                .tag(1)

                NavigationStack {
                    InsightsView()
                }
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
            }
            .accentColor(.tfBlue)
            // New task sheet at root level so it covers everything
            .sheet(isPresented: $vm.showNewTaskSheet) {
                NavigationStack {
                    NewTaskView()
                        .navigationDestination(isPresented: $vm.showEstimateReview) {
                            EstimateReviewView()
                        }
                }
                .environmentObject(vm)
            }
            // Full-screen cover for active timer — includes its own banner overlay
            .fullScreenCover(isPresented: $vm.showActiveTask) {
                ZStack(alignment: .top) {
                    NavigationStack {
                        ActiveTaskView()
                    }
                    .environmentObject(vm)

                    // Banner inside the Active Task cover so it's visible here too
                    if vm.warningState != .none, let task = vm.activeTask {
                        WarningBanner(
                            state: vm.warningState,
                            taskName: task.title,
                            estimateMinutes: task.finalEstimateMinutes,
                            elapsedMinutes: vm.elapsedMinutes,
                            onFinish: { vm.finishTask() },
                            onContinue: { vm.continueTask() }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.warningState)
                        .zIndex(200)
                    }
                }
            }
            // Full-screen cover for reflection
            // onDismiss handles swipe-down: discards if not yet saved (nil-guarded, no-op after save)
            .fullScreenCover(isPresented: $vm.showReflection, onDismiss: {
                vm.discardReflection()
            }) {
                NavigationStack {
                    ReflectionView()
                }
                .environmentObject(vm)
            }

            // ── Global warning banner — visible on any tab even if ActiveTask is not open ──
            if vm.warningState != .none, let task = vm.activeTask, !vm.showActiveTask {
                WarningBanner(
                    state: vm.warningState,
                    taskName: task.title,
                    estimateMinutes: task.finalEstimateMinutes,
                    elapsedMinutes: vm.elapsedMinutes,
                    onFinish: { vm.finishTask() },
                    onContinue: { vm.continueTask() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.warningState)
                .zIndex(100)
            }
        }
    }
}
