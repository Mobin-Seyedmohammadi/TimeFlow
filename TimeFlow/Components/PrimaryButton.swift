import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let style: PrimaryButtonStyle
    let action: () -> Void

    init(_ title: String, icon: String? = nil, style: PrimaryButtonStyle = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(style.background)
            .foregroundColor(style.foreground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style.border, lineWidth: style.borderWidth)
            )
        }
    }
}

enum PrimaryButtonStyle {
    case blue, orange, outline, ghost, destructive

    var background: Color {
        switch self {
        case .blue: return .tfBlue
        case .orange: return .tfOrange
        case .outline: return .clear
        case .ghost: return .clear
        case .destructive: return Color(hex: "DC2626")
        }
    }

    var foreground: Color {
        switch self {
        case .blue: return .white
        case .orange: return .white
        case .outline: return .tfBlue
        case .ghost: return .tfDark
        case .destructive: return .white
        }
    }

    var border: Color {
        switch self {
        case .outline: return .tfBlue
        case .ghost: return Color.black.opacity(0.15)
        default: return .clear
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .outline: return 1.5
        case .ghost: return 1
        default: return 0
        }
    }
}
