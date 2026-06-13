import SwiftUI

// MARK: - Floating Tab Bar (2 tabs: Today | Insights, Capsule pill)

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "sun.min",                    label: "Today",    index: 0)
            tabItem(icon: "chart.line.uptrend.xyaxis",  label: "Insights", index: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.92, green: 0.80, blue: 0.72).opacity(0.85))
                            .frame(width: 52, height: 52)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(
                            isSelected
                                ? Color(red: 0.65, green: 0.40, blue: 0.25)
                                : .gray
                        )
                }
                if !isSelected {
                    Text(label)
                        .font(Font.dmSans(10))
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
        ZStack(alignment: .top) {

            // ── Tab content: Today (0) | Insights (1) ─────────────────────────
            ZStack {
                if vm.selectedTab == 0 {
                    NavigationStack { TodayView() }
                        .transition(.opacity)
                } else {
                    NavigationStack { InsightsView() }
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
