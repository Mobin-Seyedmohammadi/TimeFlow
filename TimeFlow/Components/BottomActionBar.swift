import SwiftUI

struct BottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.black.opacity(0.08))
            VStack(spacing: 10) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .background(Color.tfBackground)
        }
    }
}
