import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "sun.min", label: "Today", index: 0)
            tabItem(icon: "chart.line.uptrend.xyaxis", label: "Insights", index: 1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.45))
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F0D8C8"))
                            .frame(width: 52, height: 38)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Color(hex: "C0603A") : Color(hex: "888888"))
                }
                if !isSelected {
                    Text(label)
                        .font(Font.dmSans(11))
                        .foregroundColor(Color(hex: "888888"))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct MainTabView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    private var alertingSession: ActiveTaskSession? {
        vm.activeSessions.first(where: { $0.warningState != .none })
    }

    var body: some View {
        ZStack(alignment: .top) {

            // ── Main content ───────────────────────────────────────────────────
            ZStack {
                if vm.selectedTab == 0 {
                    NavigationStack {
                        TodayView()
                    }
                    .transition(.opacity)
                } else {
                    NavigationStack {
                        InsightsView()
                    }
                    .transition(.opacity)
                }
            }
            .padding(.bottom, 90)

            // ── Global warning banner ──────────────────────────────────────────
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

            // ── Floating tab bar ───────────────────────────────────────────────
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $vm.selectedTab)
                    .padding(.bottom, 20)
            }
            .ignoresSafeArea(edges: .bottom)
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
