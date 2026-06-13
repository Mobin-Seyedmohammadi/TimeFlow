import SwiftUI

// MARK: - Floating Tab Bar (2 tabs: Today | Insights, Capsule pill)

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "sun.min",                   label: "Today",    index: 0)
            tabItem(icon: "chart.line.uptrend.xyaxis", label: "Insights", index: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
        .padding(.horizontal, 60)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        Button(action: { selectedTab = index }) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.91, green: 0.78, blue: 0.68))
                            .frame(width: 48, height: 48)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(
                            isSelected
                                ? Color(red: 0.60, green: 0.35, blue: 0.18)
                                : .gray
                        )
                }
                if !isSelected {
                    Text(label)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    private var alertingSession: ActiveTaskSession? {
        vm.activeSessions.first(where: { $0.warningState != .none })
    }

    var body: some View {
        ZStack {
            // ── Tab content fills the full screen — NO bottom padding gap ──────
            // .safeAreaInset reserves space at the bottom so content stays
            // above the floating tab bar without any opaque background behind it.
            Group {
                if vm.selectedTab == 0 {
                    NavigationStack { TodayView() }
                        .transition(.opacity)
                } else {
                    NavigationStack { InsightsView() }
                        .transition(.opacity)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Transparent spacer — only reserves layout height, shows nothing
                Color.clear.frame(height: 90)
            }

            // ── Global warning banner ──────────────────────────────────────────
            if let session = alertingSession, !vm.showActiveTask {
                VStack {
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
                    Spacer()
                }
                .zIndex(100)
            }

            // ── Floating tab bar — transparent VStack, pill only has material ──
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $vm.selectedTab)
            }
            .zIndex(50)
        }
        // New task sheet
        .sheet(isPresented: $vm.showNewTaskSheet) {
            NavigationStack {
                NewTaskView()
            }
            .environmentObject(vm)
            .presentationDetents([.large])
            .presentationBackground {
                AppGradients.newTask
            }
        }
        // Active task fullscreen cover
        .fullScreenCover(isPresented: $vm.showActiveTask) {
            ZStack(alignment: .top) {
                NavigationStack {
                    ActiveTaskView()
                }
                .environmentObject(vm)

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
        // Reflection fullscreen cover
        .fullScreenCover(isPresented: $vm.showReflection, onDismiss: {
            vm.discardReflection()
        }) {
            NavigationStack {
                ReflectionView()
            }
            .environmentObject(vm)
        }
    }
}
