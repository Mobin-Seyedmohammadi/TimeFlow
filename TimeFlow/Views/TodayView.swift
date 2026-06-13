import SwiftUI

struct TFLogo: View {
    var body: some View {
        ZStack {
            Text("F")
                .font(.custom("DMSans-Bold", size: 22))
                .foregroundColor(Color(hex: "1A2240"))
                .offset(x: 4, y: 0)
            Text("T")
                .font(.custom("DMSans-Bold", size: 22))
                .foregroundColor(Color(hex: "C0603A"))
                .offset(x: -4, y: 0)
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    // MARK: - New Task CTA

    private var newTaskCTA: some View {
        Button(action: { vm.startNewTask() }) {
            ZStack {
                // Ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)

                // The button itself
                Circle()
                    .fill(Color.tfBlue)
                    .frame(width: 180, height: 180)

                Text("New Task")
                    .font(Font.dmSans(20, weight: .medium))
                    .foregroundColor(.white)
                    .kerning(1.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Floating icon buttons

    private var floatingButtons: some View {
        VStack(spacing: 8) {
            // Bell / Alerts button
            floatingIconButton(
                icon: "bell.fill",
                label: "Alerts",
                badge: vm.activeSessions.contains(where: { $0.warningState != .none })
            ) {
                // Alerts action — tapping opens the first alerting session
                if let alerting = vm.activeSessions.first(where: { $0.warningState != .none }) {
                    vm.focusedSessionID = alerting.id
                    vm.showActiveTask = true
                }
            }

            // Active timer button — only visible when there's an active session
            if !vm.activeSessions.isEmpty {
                floatingIconButton(
                    icon: "timer",
                    label: "Active",
                    badge: false
                ) {
                    if let session = vm.activeSessions.first {
                        vm.focusedSessionID = session.id
                        vm.showActiveTask = true
                    }
                }
            }
        }
    }

    private func floatingIconButton(icon: String, label: String, badge: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    Circle()
                        .fill(Color.white.opacity(0.3))
                    Circle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "888888"))

                    if badge {
                        Circle()
                            .fill(Color.tfOrange)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())

            Text(label)
                .font(Font.dmSans(10))
                .foregroundColor(Color(hex: "888888"))
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppGradients.today

            VStack(spacing: 24) {
                Spacer()

                // Active task cards (if any)
                if !vm.activeSessions.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
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
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 260)
                }

                // Center CTA
                newTaskCTA

                Spacer()
            }

            // Floating trailing buttons ~30% from top
            .overlay(alignment: .trailing) {
                VStack {
                    Spacer().frame(height: UIScreen.main.bounds.height * 0.28)
                    floatingButtons
                        .padding(.trailing, 16)
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TFLogo()
            }
        }
    }
}
