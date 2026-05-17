import SwiftUI

struct StateAwareTaskCard: View {
    let task: TimeFlowTask
    let elapsedMinutes: Double
    let isRunning: Bool
    let warningState: WarningState
    let onOpen: () -> Void

    @EnvironmentObject var vm: TimeFlowViewModel

    private var progressFraction: Double {
        guard task.finalEstimateMinutes > 0 else { return 0 }
        return min(elapsedMinutes / Double(task.finalEstimateMinutes), 1.0)
    }

    private var stateColor: Color {
        switch warningState {
        case .none: return task.status == .paused ? Color(hex: "D97706") : .tfBlue
        case .nearLimit, .reachedLimit: return .tfOrange
        case .overtime: return .tfOrange
        }
    }

    private var stateLabel: String {
        if !isRunning && task.status == .paused { return "Paused" }
        switch warningState {
        case .none: return isRunning ? "Active" : "Ready"
        case .nearLimit: return "Near Limit"
        case .reachedLimit: return "Time Reached"
        case .overtime: return "Overtime"
        }
    }

    private var stateIcon: String {
        if !isRunning && task.status == .paused { return "pause.circle.fill" }
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.tfDark)

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stateColor)
                                .frame(width: geo.size.width * progressFraction, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: progressFraction)
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
                        .foregroundColor(.secondary)
                        Spacer()
                        Text("of \(task.finalEstimateMinutes) min")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                if warningState == .overtime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.system(size: 12))
                        Text("Extra time: +\(Int(vm.overtimeMinutes)) min")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.tfOrange)
                }

                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Tap to open")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(stateColor)
                }
            }
            .padding(16)
            .background(Color.tfCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(stateColor.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: stateColor.opacity(0.1), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
