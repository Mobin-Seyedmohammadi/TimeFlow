import SwiftUI

/// Full-width orange banner that appears at the top of the screen when a warning fires.
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text(headline)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            Text(subtext)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.90))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "FF4200"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white)
                        .cornerRadius(9)
                }

                Button(action: onContinue) {
                    Text(continueLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white.opacity(0.20))
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.white.opacity(0.50), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "FF4200"))
        .cornerRadius(0)  // flush edge-to-edge at the top
        .shadow(color: Color(hex: "FF4200").opacity(0.35), radius: 12, x: 0, y: 6)
    }
}
