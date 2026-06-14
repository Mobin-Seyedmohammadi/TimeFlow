import SwiftUI

// MARK: - Floating frosted-glass pill tab bar
private struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var indicatorNS

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                HStack(spacing: 0) {
                    pillButton(icon: "sun.max.fill",              tag: 0)
                    pillButton(icon: "chart.line.uptrend.xyaxis", tag: 1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .glassEffect(in: Capsule())
        } else {
            HStack(spacing: 0) {
                pillButton(icon: "sun.max.fill",              tag: 0)
                pillButton(icon: "chart.line.uptrend.xyaxis", tag: 1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.20), radius: 12, x: 0, y: 5)
        }
    }

    private func pillButton(icon: String, tag: Int) -> some View {
        let active = selectedTab == tag
        return Button { selectedTab = tag } label: {
            ZStack {
                // Inner pill — bottom layer
                if active {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .matchedGeometryEffect(id: "indicator", in: indicatorNS)
                }
                // Icon — top layer, always fully visible
                Image(systemName: icon)
                    .font(.system(size: 22, weight: active ? .semibold : .regular))
                    .foregroundColor(active ? Color(red: 0.133, green: 0, blue: 1) : Color(.systemGray))
            }
            .frame(width: 68, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }
}

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
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)

                NavigationStack {
                    InsightsView()
                }
                .toolbar(.hidden, for: .tabBar)
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
        .overlay(alignment: .bottom) {
            FloatingTabBar(selectedTab: $vm.selectedTab)
                .padding(.bottom, 16)
        }
    }
}
