import SwiftUI

struct BottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .background(
                .ultraThinMaterial
            )
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
    }
}
