import SwiftUI

extension Font {
    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("DMSans-Bold", size: size)
        case .medium:
            return .custom("DMSans-Medium", size: size)
        default:
            return .custom("DMSans-Regular", size: size)
        }
    }
}
