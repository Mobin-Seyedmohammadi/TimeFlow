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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.tfDark)
            }

            Text("You planned \(estimateMinutes) min for this task. You have used \(Int(elapsedMinutes)) min.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(.system(size: 15, weight: .semibold))
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
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.tfOrange.opacity(0.12))
                    .foregroundColor(.tfOrange)
                    .cornerRadius(11)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(Color.tfCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.tfOrange.opacity(0.4), lineWidth: 1.5)
        )
        .overlay(
            Rectangle()
                .fill(Color.tfOrange)
                .frame(width: 4)
                .cornerRadius(2),
            alignment: .leading
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.tfDark)
            }

            Text("Are you finished or still working on this task?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(action: onFinish) {
                    Text("Finish Task")
                        .font(.system(size: 15, weight: .semibold))
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
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.tfOrange.opacity(0.12))
                    .foregroundColor(.tfOrange)
                    .cornerRadius(11)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(Color.tfCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.tfOrange, lineWidth: 1.5)
        )
        .overlay(
            Rectangle()
                .fill(Color.tfOrange)
                .frame(width: 4)
                .cornerRadius(2),
            alignment: .leading
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.tfOrange)
                Text("TimeFlow will use this to improve your future suggestions.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onFinish) {
                Text("Finish")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Color.tfOrange)
                    .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Color.tfOrange.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tfOrange.opacity(0.3), lineWidth: 1))
    }
}
