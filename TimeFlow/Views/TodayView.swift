import SwiftUI

// MARK: - TF Logotype

struct TFLogo: View {
    var body: some View {
        ZStack {
            Text("T")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.72, green: 0.36, blue: 0.20))
                .offset(x: -7, y: 0)
            Text("F")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.10, green: 0.13, blue: 0.25))
                .offset(x: 7, y: 0)
        }
    }
}

// MARK: - TodayView

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    // MARK: Aurora background — multi-blob ellipse gradient

    private var auroraBackground: some View {
        ZStack {
            Color(red: 0.94, green: 0.90, blue: 0.93)

            // Top-left lavender blob
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.72, green: 0.67, blue: 0.85).opacity(0.85), .clear],
                    center: .center, startRadius: 0, endRadius: 220))
                .frame(width: 380, height: 340)
                .offset(x: -80, y: -300)

            // Top-right peach/salmon blob
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.88, green: 0.72, blue: 0.63).opacity(0.9), .clear],
                    center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 360, height: 320)
                .offset(x: 120, y: -280)

            // Bottom-right mauve blob
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.78, green: 0.68, blue: 0.75).opacity(0.75), .clear],
                    center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 340, height: 300)
                .offset(x: 130, y: 320)

            // Bottom-left peach blob
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.90, green: 0.78, blue: 0.70).opacity(0.7), .clear],
                    center: .center, startRadius: 0, endRadius: 180))
                .frame(width: 300, height: 280)
                .offset(x: -100, y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: New Task button — centered, with ambient glow

    private var newTaskButton: some View {
        Button(action: { vm.startNewTask() }) {
            ZStack {
                // Ambient white bloom behind the circle
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.white.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 145))
                    .frame(width: 290, height: 290)

                // The blue circle button
                Circle()
                    .fill(Color(red: 0.16, green: 0.02, blue: 0.95))
                    .frame(width: 180, height: 180)
                    .overlay(
                        Text("New Task")
                            .font(.system(size: 20, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(.white)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Floating right-side buttons

    private var alertsButton: some View {
        VStack(spacing: 6) {
            Button(action: {
                if let alerting = vm.activeSessions.first(where: { $0.warningState != .none }) {
                    vm.focusedSessionID = alerting.id
                    vm.showActiveTask = true
                }
            }) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    Circle().fill(Color.white.opacity(0.3))
                    Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
                    Image(systemName: "record.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)

                    if vm.activeSessions.contains(where: { $0.warningState != .none }) {
                        Circle()
                            .fill(Color.tfOrange)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Alerts")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }

    private var activeButton: some View {
        VStack(spacing: 6) {
            Button(action: {
                if let session = vm.activeSessions.first {
                    vm.focusedSessionID = session.id
                    vm.showActiveTask = true
                }
            }) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    Circle().fill(Color.white.opacity(0.3))
                    Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Active")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            // 1. Aurora background
            auroraBackground

            // 2. Centered content (active cards above, button below)
            VStack(spacing: 24) {
                Spacer()

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

                newTaskButton

                Spacer()
            }

            // 3. Right-side floating buttons — top-right, 80pt below nav bar
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        alertsButton
                        if !vm.activeSessions.isEmpty {
                            activeButton
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 80)
                }
                Spacer()
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
