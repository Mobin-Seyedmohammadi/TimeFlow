import SwiftUI

struct WarningBanner: View {
    let state: WarningState
    let taskName: String
    let estimateMinutes: Int
    let elapsedMinutes: Double
    let onFinish: () -> Void
    let onContinue: () -> Void

    private var headline: String {
        switch state {
        case .none:         return ""
        case .nearLimit:    return "Almost at your estimate!"
        case .reachedLimit: return "Time is up!"
        case .overtime:
            let extra = max(0, Int(elapsedMinutes) - estimateMinutes)
            return "Overtime: +\(extra) min"
        }
    }

    private var subtext: String {
        switch state {
        case .none:         return ""
        case .nearLimit:    return "You planned \(estimateMinutes) min for \"\(taskName)\". Are you done or still going?"
        case .reachedLimit: return "\"\(taskName)\" has reached its estimate. Are you finished or still working?"
        case .overtime:     return "Still working on \"\(taskName)\". Tap Finish when done."
        }
    }

    private var continueLabel: String {
        state == .overtime ? "Still Going" : "Still Ongoing"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: state == .overtime
                      ? "clock.badge.exclamationmark.fill"
                      : "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.tfOrange)

                Text(headline)
                    .font(Font.dmSans(15, weight: .bold))
                    .foregroundColor(.tfDark)

                Spacer()
            }

            Text(subtext)
                .font(Font.dmSans(13))
                .foregroundColor(.tfSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(Font.dmSans(14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.tfOrange)
                        .cornerRadius(9)
                }

                Button(action: onContinue) {
                    Text(continueLabel)
                        .font(Font.dmSans(14, weight: .medium))
                        .foregroundColor(.tfOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(.ultraThinMaterial)
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.tfOrange.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color.tfOrange.opacity(0.12))
                Rectangle()
                    .strokeBorder(Color.tfOrange.opacity(0.4), lineWidth: 1)
            }
        )
        .shadow(color: Color.tfOrange.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}
