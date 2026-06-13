import SwiftUI

struct AppGradients {

    @ViewBuilder static var today: some View {
        ZStack {
            Color(hex: "F0EBF5")
            RadialGradient(
                colors: [Color(hex: "C8BFDF").opacity(0.7), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            RadialGradient(
                colors: [Color(hex: "E8C4B0").opacity(0.6), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 350
            )
            RadialGradient(
                colors: [Color(hex: "D4B8C8").opacity(0.5), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 300
            )
            RadialGradient(
                colors: [Color(hex: "F2D4CC").opacity(0.4), Color.clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder static var insights: some View {
        ZStack {
            Color(hex: "EDF2F5")
            RadialGradient(
                colors: [Color(hex: "BFD0E8").opacity(0.6), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            RadialGradient(
                colors: [Color(hex: "BFD9D4").opacity(0.55), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
            RadialGradient(
                colors: [Color(hex: "C8BFDF").opacity(0.4), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder static var newTask: some View {
        ZStack {
            Color(hex: "F5EFF5")
            RadialGradient(
                colors: [Color(hex: "D4B8C8").opacity(0.55), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 350
            )
            RadialGradient(
                colors: [Color(hex: "C8BFDF").opacity(0.5), Color.clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder static var activeTask: some View {
        ZStack {
            Color(hex: "EEF0F8")
            RadialGradient(
                colors: [Color(hex: "2B00FF").opacity(0.08), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            RadialGradient(
                colors: [Color(hex: "BFD0E8").opacity(0.6), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 350
            )
            RadialGradient(
                colors: [Color(hex: "C8BFDF").opacity(0.45), Color.clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder static var reflection: some View {
        ZStack {
            Color(hex: "F5F0EC")
            RadialGradient(
                colors: [Color(hex: "E8C4B0").opacity(0.6), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 380
            )
            RadialGradient(
                colors: [Color(hex: "F2D4CC").opacity(0.5), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 320
            )
            RadialGradient(
                colors: [Color(hex: "C8BFDF").opacity(0.35), Color.clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder static var estimateReview: some View {
        newTask
    }
}
