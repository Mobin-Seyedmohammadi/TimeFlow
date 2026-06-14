import SwiftUI

struct StateAwareTaskCard: View {
    let task: TimeFlowTask
    let elapsedMinutes: Double
    let isRunning: Bool
    let warningState: WarningState
    let onOpen: () -> Void

    private var isActuallyOvertime: Bool {
        elapsedMinutes >= Double(task.finalEstimateMinutes)
    }

    private var overtimeMinutes: Double {
        max(0, elapsedMinutes - Double(task.finalEstimateMinutes))
    }

    private var progressFraction: Double {
        guard task.finalEstimateMinutes > 0 else { return 0 }
        return min(elapsedMinutes / Double(task.finalEstimateMinutes), 1.0)
    }

    private var stateColor: Color {
        if isActuallyOvertime { return .tfOrange }
        switch warningState {
        case .none: return task.status == .paused ? Color(hex: "D97706") : Color(red: 0.133, green: 0, blue: 1)
        case .nearLimit, .reachedLimit: return .tfOrange
        case .overtime: return .tfOrange
        }
    }

    private var stateLabel: String {
        if !isRunning && task.status == .paused { return "Paused" }
        if isActuallyOvertime { return "Overtime" }
        switch warningState {
        case .none: return isRunning ? "Active" : "Ready"
        case .nearLimit: return "Near Limit"
        case .reachedLimit: return "Time Reached"
        case .overtime: return "Overtime"
        }
    }

    private var stateIcon: String {
        if !isRunning && task.status == .paused { return "pause.circle.fill" }
        if isActuallyOvertime { return "clock.badge.exclamationmark.fill" }
        switch warningState {
        case .none: return isRunning ? "timer" : "play.circle.fill"
        case .nearLimit: return "exclamationmark.triangle.fill"
        case .reachedLimit: return "flag.checkered"
        case .overtime: return "clock.badge.exclamationmark.fill"
        }
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatusChip(stateLabel, icon: stateIcon, color: stateColor)
                    Spacer()
                    StatusChip(category: task.category)
                }

                Text(task.title)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "1A1A2E"))

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stateColor)
                                .frame(width: geo.size.width * progressFraction, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progressFraction)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(Int(elapsedMinutes)) min elapsed")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(hex: "8A8AAA"))
                        Spacer()
                        Text("of \(task.finalEstimateMinutes) min")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8AAA"))
                    }
                }

                if isActuallyOvertime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.system(size: 12))
                        Text("Extra time: +\(Int(overtimeMinutes)) min")
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundColor(.tfOrange)
                }

                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Tap to open")
                            .font(.system(size: 13, weight: .regular))
                            .tracking(0.5)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundColor(stateColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(stateColor.opacity(0.4), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
