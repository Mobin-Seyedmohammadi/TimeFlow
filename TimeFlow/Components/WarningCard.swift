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
                    .font(.system(size: 15, weight: .light))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "1A1A2E"))
            }

            Text("You planned \(estimateMinutes) min for this task. You have used \(Int(elapsedMinutes)) min.")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(hex: "4A4A6A"))

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "1A1A2E"))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

                Button(action: onContinue) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.forward.circle.fill")
                        Text("Still Ongoing")
                            .fontWeight(.regular)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.tfOrange)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "FF6B00").opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.tfOrange.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var reachedLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.tfOrange)
                    .font(.system(size: 16))
                Text("Estimated time reached")
                    .font(.system(size: 15, weight: .light))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "1A1A2E"))
            }

            Text("Are you finished or still working on this task?")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(hex: "4A4A6A"))

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(red: 0.133, green: 0, blue: 1))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

                Button(action: onContinue) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Continue Working")
                            .fontWeight(.regular)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.tfOrange)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "FF6B00").opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.tfOrange.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var overtimeCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .foregroundColor(.tfOrange)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text("Extra time: +\(Int(overtimeMinutes)) min")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.5)
                    .foregroundColor(.tfOrange)
                Text("TimeFlow will use this to improve your future suggestions.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(hex: "4A4A6A"))
            }
            Spacer()
            Button(action: onFinish) {
                Text("Finish")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.5)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Color.tfOrange)
                    .cornerRadius(12)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "FF6B00").opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.tfOrange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
