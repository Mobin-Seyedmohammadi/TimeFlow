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
                .font(.system(size: 11, weight: .regular))
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .tracking(0.5)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        )
    }
}

struct EstimationLabelChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .regular))
            .tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
            )
    }
}
