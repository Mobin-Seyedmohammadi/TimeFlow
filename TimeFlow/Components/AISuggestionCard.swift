import SwiftUI

struct AISuggestionCard: View {
    let suggestion: AISuggestion
    let userEstimate: Int
    let showExplanation: Bool
    let onUse: () -> Void
    let onKeep: () -> Void
    let onAdjust: (() -> Void)?

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

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
        case .low:    return Color.white.opacity(0.2)
        case .medium: return Color(hex: "D97706").opacity(0.15)
        case .high:   return accentBlue.opacity(0.12)
        }
    }

    private var badgeForeground: Color {
        switch suggestion.confidence {
        case .low:    return Color(hex: "8A8AAA")
        case .medium: return Color(hex: "D97706")
        case .high:   return accentBlue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ─────────────────────────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(accentBlue)
                Text("AI Suggestion")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(1.0)
                    .foregroundColor(accentBlue)
                Spacer()
                // Confidence badge
                Text(badgeLabel)
                    .font(.system(size: 12, weight: .regular))
                    .tracking(0.5)
                    .foregroundColor(badgeForeground)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(badgeBackground)
                            .overlay(Capsule().stroke(badgeForeground.opacity(0.3), lineWidth: 1))
                    )
            }

            // ── Main suggested time ────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TimeFlow suggests")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "8A8AAA"))
                        Text("\(suggestion.suggestedMinutes) min")
                            .font(.system(size: 36, weight: .light, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A2E"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Your estimate")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "8A8AAA"))
                        Text("\(userEstimate) min")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color(hex: "4A4A6A"))
                    }
                }

                // Prediction interval
                HStack(spacing: 5) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8AAA"))
                    Text("\(suggestion.confidencePercent)% chance: \(suggestion.lowBound)–\(suggestion.highBound) min")
                        .font(.system(size: 13, weight: .light))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "8A8AAA"))
                }
                .padding(.top, 2)
            }

            // ── Difference indicator ───────────────────────────────────────────
            let diff = suggestion.suggestedMinutes - userEstimate
            if diff != 0 {
                HStack(spacing: 6) {
                    Image(systemName: diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(diff > 0 ? .tfOrange : accentBlue)
                        .font(.system(size: 13))
                    Text(diff > 0
                         ? "AI suggests +\(diff) min more than your estimate"
                         : "AI suggests \(abs(diff)) min less than your estimate")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(Color(hex: "4A4A6A"))
                }
            }

            // ── Explanation + data source (both gated by showExplanation) ─────
            if showExplanation {
                Text(suggestion.explanation)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "4A4A6A"))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentBlue.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accentBlue.opacity(0.15), lineWidth: 0.5))
                    )

                Text("Source: \(suggestion.dataSource)")
                    .font(.system(size: 11, weight: .light))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "8A8AAA"))
            }

            // ── Actions ────────────────────────────────────────────────────────
            VStack(spacing: 8) {
                // Use AI — primary blue with glow
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(accentBlue.opacity(0.4))
                        .frame(height: 68)
                        .blur(radius: 18)
                        .padding(.horizontal, 20)

                    Button(action: onUse) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Use AI Suggestion (\(suggestion.suggestedMinutes) min)")
                                .font(.system(size: 15, weight: .regular))
                                .tracking(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(accentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                }

                // Keep my estimate — frosted glass
                Button(action: onKeep) {
                    Text("Keep My Estimate (\(userEstimate) min)")
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(.ultraThinMaterial)
                        .foregroundColor(accentBlue)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(accentBlue.opacity(0.3), lineWidth: 1))
                }

                if let onAdjust = onAdjust {
                    Button(action: onAdjust) {
                        Text("Adjust Manually")
                            .font(.system(size: 15, weight: .regular))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "8A8AAA"))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.25)))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(accentBlue.opacity(0.3), lineWidth: 1))
        )
    }
}
