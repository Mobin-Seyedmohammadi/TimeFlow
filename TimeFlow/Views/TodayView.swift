import SwiftUI

// MARK: - TF Logotype

struct TFLogo: View {
    var body: some View {
        ZStack {
            Text("T")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.72, green: 0.36, blue: 0.20))
                .offset(x: -9, y: 0)
            Text("F")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.10, green: 0.13, blue: 0.25))
                .offset(x: 5, y: 0)
        }
    }
}

// MARK: - TodayView

struct TodayView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    // MARK: Aurora background — blobs are ambient light, not visible shapes

    private var auroraBackground: some View {
        ZStack {
            Color(red: 0.94, green: 0.90, blue: 0.93)

            // Top-left lavender — frame +40%, endRadius +50%, opacity ≤0.45
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.72, green: 0.67, blue: 0.85).opacity(0.40), .clear],
                    center: .center, startRadius: 0, endRadius: 330))
                .frame(width: 532, height: 476)
                .offset(x: -80, y: -300)

            // Top-right peach/salmon
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.88, green: 0.72, blue: 0.63).opacity(0.40), .clear],
                    center: .center, startRadius: 0, endRadius: 300))
                .frame(width: 504, height: 448)
                .offset(x: 120, y: -280)

            // Bottom-right mauve
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.78, green: 0.68, blue: 0.75).opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: 300))
                .frame(width: 476, height: 420)
                .offset(x: 130, y: 320)

            // Bottom-left peach
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.90, green: 0.78, blue: 0.70).opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: 270))
                .frame(width: 420, height: 392)
                .offset(x: -100, y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: New Task button — centered, with ambient glow

    private var newTaskButton: some View {
        Button(action: { vm.startNewTask() }) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.white.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 145))
                    .frame(width: 290, height: 290)

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

    // MARK: Body

    var body: some View {
        ZStack {
            auroraBackground

            // Active task cards anchored to the top of the content area
            if !vm.activeSessions.isEmpty {
                VStack {
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
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(maxHeight: 260)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 16)
            }

            // New Task button at 42% from top, perfectly centered on x-axis
            GeometryReader { geo in
                newTaskButton
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
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
