import SwiftUI

/// Full-width frosted-glass banner with orange tint that appears when a warning fires.
/// Dismisses only when the user taps "Finish Task" or "Still Ongoing".
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
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "D97706"))

                Text(headline)
                    .font(.system(size: 15, weight: .regular))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "1A1A2E"))

                Spacer()
            }

            Text(subtext)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(Color(hex: "4A4A6A"))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(.system(size: 14, weight: .regular))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color(hex: "D97706"))
                        .cornerRadius(12)
                }

                Button(action: onContinue) {
                    Text(continueLabel)
                        .font(.system(size: 14, weight: .regular))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "D97706"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "D97706").opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color(hex: "FF6B00").opacity(0.12)
        )
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color(hex: "FF6B00").opacity(0.4))
                .frame(height: 1),
            alignment: .bottom
        )
        .cornerRadius(0)  // flush edge-to-edge at the top
    }
}
