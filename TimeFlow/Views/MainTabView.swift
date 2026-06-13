import SwiftUI

// MARK: - Floating Tab Bar (4 tabs, pill/Capsule shape)

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "sun.min",                    label: "Today",    index: 0)
            tabItem(icon: "line.3.horizontal",          label: "History",  index: 1)
            tabItem(icon: "arrow.up.right",             label: "Insights", index: 2)
            tabItem(icon: "scope",                      label: "Settings", index: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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

            // ── Tab content — 4 tabs: Today(0) History(1) Insights(2) Settings(3) ──
            ZStack {
                switch vm.selectedTab {
                case 0:
                    NavigationStack { TodayView() }
                        .transition(.opacity)
                case 1:
                    NavigationStack { HistoryView() }
                        .transition(.opacity)
                case 2:
                    NavigationStack { InsightsView() }
                        .transition(.opacity)
                case 3:
                    NavigationStack { SettingsView() }
                        .transition(.opacity)
                default:
                    NavigationStack { TodayView() }
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
