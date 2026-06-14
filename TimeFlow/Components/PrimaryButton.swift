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

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1) // #2200FF

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow bloom — only for .blue style
                if style == .blue {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(accentBlue.opacity(0.4))
                        .frame(height: 70)
                        .blur(radius: 20)
                        .padding(.horizontal, 20)
                }

                // Button itself
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .regular))
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .regular))
                        .tracking(1.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(style.background)
                .foregroundColor(style.foreground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(style.border, lineWidth: style.borderWidth)
                )
            }
        }
    }
}

enum PrimaryButtonStyle {
    case blue, orange, outline, ghost, destructive

    var background: Color {
        switch self {
        case .blue: return Color(red: 0.133, green: 0, blue: 1)
        case .orange: return .tfOrange
        case .outline: return .clear
        case .ghost: return Color.white.opacity(0.2)
        case .destructive: return Color(hex: "DC2626")
        }
    }

    var foreground: Color {
        switch self {
        case .blue: return .white
        case .orange: return .white
        case .outline: return Color(red: 0.133, green: 0, blue: 1)
        case .ghost: return Color(hex: "4A4A6A")
        case .destructive: return .white
        }
    }

    var border: Color {
        switch self {
        case .outline: return Color(red: 0.133, green: 0, blue: 1)
        case .ghost: return Color.white.opacity(0.4)
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
