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

    // MARK: - Confidence badge

    private var badgeLabel: String {
        switch suggestion.confidence {
        case .low:
            return suggestion.dataSource == "General default" ? "Default" : "1 task"
        case .medium:
            return "Low confidence"
        case .high:
            return "Good confidence"
        }
    }

    private var badgeBackground: Color {
        switch suggestion.confidence {
        case .low:    return Color(.systemGray5)
        case .medium: return Color(hex: "D97706").opacity(0.15)
        case .high:   return Color.tfBlue.opacity(0.12)
        }
    }

    private var badgeForeground: Color {
        switch suggestion.confidence {
        case .low:    return .tfSecondary
        case .medium: return Color(hex: "D97706")
        case .high:   return .tfBlue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ──────────────────────────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.tfBlue)
                Text("AI Suggestion")
                    .font(Font.dmSans(13, weight: .medium))
                    .foregroundColor(.tfBlue)
                Spacer()
                // Confidence badge
                Text(badgeLabel)
                    .font(Font.dmSans(12, weight: .medium))
                    .foregroundColor(badgeForeground)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(badgeBackground)
                    .clipShape(Capsule())
            }

            // ── Main suggested time ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TimeFlow suggests")
                            .font(Font.dmSans(13))
                            .foregroundColor(.tfSecondary)
                        Text("\(suggestion.suggestedMinutes) min")
                            .font(Font.dmSans(36, weight: .bold))
                            .foregroundColor(.tfDark)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Your estimate")
                            .font(Font.dmSans(13))
                            .foregroundColor(.tfSecondary)
                        Text("\(userEstimate) min")
                            .font(Font.dmSans(20, weight: .medium))
                            .foregroundColor(.tfSecondary)
                    }
                }

                // Prediction interval
                HStack(spacing: 5) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 11))
                        .foregroundColor(.tfSecondary)
                    Text("\(suggestion.confidencePercent)% chance: \(suggestion.lowBound)–\(suggestion.highBound) min")
                        .font(Font.dmSans(13))
                        .foregroundColor(.tfSecondary)
                }
                .padding(.top, 2)
            }

            // ── Difference indicator ─────────────────────────────────────────────
            let diff = suggestion.suggestedMinutes - userEstimate
            if diff != 0 {
                HStack(spacing: 6) {
                    Image(systemName: diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(diff > 0 ? .tfOrange : .tfBlue)
                        .font(.system(size: 13))
                    Text(diff > 0
                         ? "AI suggests +\(diff) min more than your estimate"
                         : "AI suggests \(abs(diff)) min less than your estimate")
                        .font(Font.dmSans(13))
                        .foregroundColor(.tfSecondary)
                }
            }

            // ── Explanation + data source ────────────────────────────────────────
            if showExplanation {
                Text(suggestion.explanation)
                    .font(Font.dmSans(14))
                    .foregroundColor(.tfSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .background(Color.tfBlue.opacity(0.06))
                    .cornerRadius(8)

                Text("Source: \(suggestion.dataSource)")
                    .font(Font.dmSans(11))
                    .foregroundColor(.tfSecondary)
            }

            // ── Actions ──────────────────────────────────────────────────────────
            VStack(spacing: 8) {
                Button(action: onUse) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use AI Suggestion (\(suggestion.suggestedMinutes) min)")
                            .font(Font.dmSans(15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.tfBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: onKeep) {
                    Text("Keep My Estimate (\(userEstimate) min)")
                        .font(Font.dmSans(15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.tfDark)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        )
                }

                if let onAdjust = onAdjust {
                    Button(action: onAdjust) {
                        Text("Adjust Manually")
                            .font(Font.dmSans(15))
                            .foregroundColor(.tfSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.35))
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.tfBlue.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
