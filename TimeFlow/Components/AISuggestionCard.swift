import SwiftUI

struct AISuggestionCard: View {
    let suggestion: AISuggestion
    let userEstimate: Int
    let showExplanation: Bool
    let onUse: () -> Void
    let onKeep: () -> Void
    let onAdjust: (() -> Void)?

    init(
        suggestion: AISuggestion,
        userEstimate: Int,
        showExplanation: Bool = true,
        onUse: @escaping () -> Void,
        onKeep: @escaping () -> Void,
        onAdjust: (() -> Void)? = nil
    ) {
        self.suggestion = suggestion
        self.userEstimate = userEstimate
        self.showExplanation = showExplanation
        self.onUse = onUse
        self.onKeep = onKeep
        self.onAdjust = onAdjust
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.tfBlue)
                Text("AI Suggestion")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.tfBlue)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(suggestion.confidence.color)
                        .frame(width: 7, height: 7)
                    Text("Confidence: \(suggestion.confidence.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Suggested time vs user estimate
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TimeFlow suggests")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(suggestion.suggestedMinutes) min")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.tfDark)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Your estimate")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(userEstimate) min")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            // Difference indicator
            let diff = suggestion.suggestedMinutes - userEstimate
            if diff != 0 {
                HStack(spacing: 6) {
                    Image(systemName: diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(diff > 0 ? .tfOrange : .tfBlue)
                        .font(.system(size: 13))
                    Text(diff > 0
                         ? "AI suggests +\(diff) min more than your estimate"
                         : "AI suggests \(abs(diff)) min less than your estimate")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            // Explanation
            if showExplanation {
                Text(suggestion.explanation)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "374151"))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .background(Color.tfBlue.opacity(0.06))
                    .cornerRadius(8)
            }

            // Disclaimer
            Text("This is a prototype suggestion. You can adjust it freely.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            // Actions
            VStack(spacing: 8) {
                Button(action: onUse) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use AI Suggestion (\(suggestion.suggestedMinutes) min)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.tfBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: onKeep) {
                    Text("Keep My Estimate (\(userEstimate) min)")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.tfBlue.opacity(0.08))
                        .foregroundColor(.tfBlue)
                        .cornerRadius(12)
                }

                if let onAdjust = onAdjust {
                    Button(action: onAdjust) {
                        Text("Adjust Manually")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.tfCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tfBlue.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: Color.tfBlue.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
