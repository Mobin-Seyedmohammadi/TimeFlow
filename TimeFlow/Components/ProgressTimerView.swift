import SwiftUI

struct ProgressTimerView: View {
    let elapsedMinutes: Double
    let estimateMinutes: Int
    let isRunning: Bool
    let warningState: WarningState

    private var progress: Double {
        guard estimateMinutes > 0 else { return 0 }
        return min(elapsedMinutes / Double(estimateMinutes), 1.0)
    }

    private var ringColor: Color {
        switch warningState {
        case .none: return Color(red: 0.133, green: 0, blue: 1) // accent blue
        case .nearLimit: return .tfOrange
        case .reachedLimit: return .tfOrange
        case .overtime: return .tfOrange
        }
    }

    private var elapsedLabel: String {
        let m = Int(elapsedMinutes)
        return String(format: "%d:%02d", m, 0)
    }

    var body: some View {
        ZStack {
            // Background ring — subtle white track
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 14)
                .frame(width: 200, height: 200)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progress)

            // Overflow ring (overtime > 100%)
            if elapsedMinutes > Double(estimateMinutes) {
                let overflow = min((elapsedMinutes - Double(estimateMinutes)) / Double(estimateMinutes), 1.0)
                Circle()
                    .trim(from: 0, to: overflow)
                    .stroke(
                        Color.tfOrange.opacity(0.4),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 228, height: 228)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: overflow)
            }

            // Center content
            VStack(spacing: 4) {
                Text(elapsedLabel)
                    .font(.system(size: 46, weight: .light, design: .monospaced))
                    .foregroundColor(Color(hex: "1A1A2E"))
                    .monospacedDigit()

                Text("elapsed")
                    .font(.system(size: 13, weight: .light))
                    .tracking(1.0)
                    .foregroundColor(Color(hex: "8A8AAA"))

                if isRunning {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ringColor)
                            .frame(width: 6, height: 6)
                        Text(warningState == .overtime ? "Overtime" : "Running")
                            .font(.system(size: 12, weight: .regular))
                            .tracking(0.5)
                            .foregroundColor(ringColor)
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10))
                        Text("Paused")
                            .font(.system(size: 12, weight: .regular))
                            .tracking(0.5)
                    }
                    .foregroundColor(Color(hex: "8A8AAA"))
                    .padding(.top, 2)
                }
            }
        }
    }
}
