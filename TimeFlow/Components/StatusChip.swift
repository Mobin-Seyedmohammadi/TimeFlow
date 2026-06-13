import SwiftUI

struct StatusChip: View {
    let label: String
    let icon: String
    let color: Color

    init(_ label: String, icon: String, color: Color) {
        self.label = label
        self.icon = icon
        self.color = color
    }

    init(status: TaskStatus) {
        self.label = status.rawValue
        self.icon = status.icon
        self.color = status.color
    }

    init(category: TaskCategory) {
        self.label = category.rawValue
        self.icon = category.icon
        self.color = category.color
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(Font.dmSans(12, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }
}

struct EstimationLabelChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(Font.dmSans(12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(Capsule())
    }
}
