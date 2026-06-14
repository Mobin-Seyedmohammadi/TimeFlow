import SwiftUI

// MARK: - Shared animated aurora / mesh-gradient background
// Used across all screens for a seamless ambient environment.
struct AuroraBackground: View {
    @State private var startTime = Date()

    private let lavender = Color(red: 0.784, green: 0.753, blue: 0.878) // #C8C0E0
    private let peach    = Color(red: 0.910, green: 0.769, blue: 0.659) // #E8C4A8
    private let cream    = Color(red: 0.941, green: 0.910, blue: 0.863) // #F0E8DC
    private let mauve    = Color(red: 0.871, green: 0.784, blue: 0.816) // #DEC8D0

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(startTime)
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    cream

                    // Lavender blob — top-left, slow drift
                    Ellipse()
                        .fill(lavender)
                        .frame(width: 400, height: 360)
                        .offset(
                            x: -w * 0.18 + CGFloat(sin(t * 0.28)) * 42,
                            y: -h * 0.22 + CGFloat(cos(t * 0.22)) * 32
                        )
                        .blur(radius: 72)

                    // Peach blob — top-right, counter-drift
                    Ellipse()
                        .fill(peach)
                        .frame(width: 360, height: 310)
                        .offset(
                            x:  w * 0.22 + CGFloat(cos(t * 0.25)) * 38,
                            y: -h * 0.18 + CGFloat(sin(t * 0.32)) * 28
                        )
                        .blur(radius: 68)

                    // Mauve blob — bottom-right, slow sway
                    Ellipse()
                        .fill(mauve)
                        .frame(width: 380, height: 340)
                        .offset(
                            x:  w * 0.20 + CGFloat(sin(t * 0.20)) * 48,
                            y:  h * 0.22 + CGFloat(cos(t * 0.26)) * 36
                        )
                        .blur(radius: 72)

                    // Soft lavender centre — gentle pulse
                    Ellipse()
                        .fill(lavender.opacity(0.45))
                        .frame(width: 320, height: 290)
                        .offset(
                            x: CGFloat(cos(t * 0.17)) * 30,
                            y: CGFloat(sin(t * 0.19)) * 24
                        )
                        .blur(radius: 82)
                }
                .frame(width: w, height: h)
                .clipped()
            }
        }
        .ignoresSafeArea()
    }
}
