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
        case .none:         return .tfBlue
        case .nearLimit:    return .tfOrange
        case .reachedLimit: return .tfOrange
        case .overtime:     return .tfOrange
        }
    }

    private var elapsedLabel: String {
        let m = Int(elapsedMinutes)
        return String(format: "%d:%02d", m, 0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 14)
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
                .animation(.easeInOut(duration: 0.5), value: progress)

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
                    .animation(.easeInOut(duration: 0.5), value: overflow)
            }

            // Center content
            VStack(spacing: 4) {
                Text(elapsedLabel)
                    .font(Font.dmSans(52, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.tfDark)

                Text("elapsed")
                    .font(Font.dmSans(13))
                    .foregroundColor(.tfSecondary)

                if isRunning {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ringColor)
                            .frame(width: 6, height: 6)
                        Text(warningState == .overtime ? "Overtime" : "Running")
                            .font(Font.dmSans(12, weight: .medium))
                            .foregroundColor(ringColor)
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10))
                        Text("Paused")
                            .font(Font.dmSans(12, weight: .medium))
                    }
                    .foregroundColor(.tfSecondary)
                    .padding(.top, 2)
                }
            }
        }
    }
}
