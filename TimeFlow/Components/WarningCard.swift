import SwiftUI

struct WarningCard: View {
    let state: WarningState
    let elapsedMinutes: Double
    let estimateMinutes: Int
    let overtimeMinutes: Double
    let onFinish: () -> Void
    let onContinue: () -> Void

    var body: some View {
        switch state {
        case .none:
            EmptyView()
        case .nearLimit:
            nearLimitCard
        case .reachedLimit:
            reachedLimitCard
        case .overtime:
            overtimeCard
        }
    }

    private var nearLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.tfOrange)
                    .font(.system(size: 16))
                Text("Almost at your estimate")
                    .font(Font.dmSans(15, weight: .bold))
                    .foregroundColor(.tfDark)
            }

            Text("You planned \(estimateMinutes) min for this task. You have used \(Int(elapsedMinutes)) min.")
                .font(Font.dmSans(14))
                .foregroundColor(.tfSecondary)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(Font.dmSans(15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.tfDark)
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }

                Button(action: onContinue) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.forward.circle.fill")
                        Text("Still Ongoing")
                            .font(Font.dmSans(15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.tfOrange)
                    .cornerRadius(11)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.35))
                RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tfOrange.opacity(0.4), lineWidth: 1.5)
            }
        )
        .shadow(color: Color.tfOrange.opacity(0.12), radius: 8, x: 0, y: 3)
    }

    private var reachedLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.tfOrange)
                    .font(.system(size: 16))
                Text("Estimated time reached")
                    .font(Font.dmSans(15, weight: .bold))
                    .foregroundColor(.tfDark)
            }

            Text("Are you finished or still working on this task?")
                .font(Font.dmSans(14))
                .foregroundColor(.tfSecondary)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(Font.dmSans(15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.tfBlue)
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }

                Button(action: onContinue) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Continue Working")
                            .font(Font.dmSans(15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.tfOrange)
                    .cornerRadius(11)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.35))
                RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tfOrange, lineWidth: 1.5)
            }
        )
        .shadow(color: Color.tfOrange.opacity(0.15), radius: 8, x: 0, y: 3)
    }

    private var overtimeCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .foregroundColor(.tfOrange)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text("Extra time: +\(Int(overtimeMinutes)) min")
                    .font(Font.dmSans(14, weight: .bold))
                    .foregroundColor(.tfOrange)
                Text("TimeFlow will use this to improve your future suggestions.")
                    .font(Font.dmSans(12))
                    .foregroundColor(.tfSecondary)
            }
            Spacer()
            Button(action: onFinish) {
                Text("Finish")
                    .font(Font.dmSans(14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Color.tfOrange)
                    .cornerRadius(10)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
    }
}
