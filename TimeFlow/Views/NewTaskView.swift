import SwiftUI

// MARK: - Step 1: Category selection

struct NewTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @Environment(\.dismiss) private var dismiss

    /// Drives the NavigationLink push to Step 2.
    @State private var pushStep2 = false
    /// Tracks which card was just tapped so we can briefly highlight it.
    @State private var tappedCategory: TaskCategory? = nil

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(TaskCategory.allCases) { cat in
                        categoryCard(cat)
                    }
                }
                .padding(16)
                .padding(.top, 4)
            }
        }
        .navigationTitle("What type of task?")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Color(hex: "8A8AAA"))
            }
        }
        // Push Step 2 onto the NavigationStack
        .navigationDestination(isPresented: $pushStep2) {
            NewTaskStep2View()
        }
    }

    private func categoryCard(_ cat: TaskCategory) -> some View {
        let isHighlighted = tappedCategory == cat
        return Button(action: {
            vm.draftCategory = cat
            tappedCategory = cat
            // Brief highlight, then push
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                tappedCategory = nil
                pushStep2 = true
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(cat.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: cat.icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(cat.color)
                }
                Text(cat.rawValue)
                    .font(.system(size: 13, weight: .light))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "1A1A2E"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(isHighlighted ? cat.color.opacity(0.22) : Color.white.opacity(0.25))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                isHighlighted ? cat.color.opacity(0.7) : Color.white.opacity(0.5),
                                lineWidth: isHighlighted ? 1.5 : 0.5
                            )
                    )
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isHighlighted)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 2: Name + estimate

struct NewTaskStep2View: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @FocusState private var titleFocused: Bool

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

    private var canProceed: Bool {
        !vm.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Task name ──────────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Task Name", systemImage: "pencil.line")
                            .font(.system(size: 13, weight: .light))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "8A8AAA"))

                        TextField("What are you going to do?", text: $vm.draftTitle)
                            .font(.system(size: 17, weight: .light))
                            .foregroundColor(Color(hex: "1A1A2E"))
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.25)))
                                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5))
                            )
                            .focused($titleFocused)
                    }

                    // ── Estimate stepper ───────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Your Estimate", systemImage: "clock")
                            .font(.system(size: 13, weight: .light))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "8A8AAA"))

                        HStack(spacing: 24) {
                            Button(action: {
                                if vm.draftUserEstimate > 5 { vm.draftUserEstimate -= 5 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(
                                        vm.draftUserEstimate > 5 ? accentBlue : Color(hex: "8A8AAA")
                                    )
                            }
                            .disabled(vm.draftUserEstimate <= 5)

                            VStack(spacing: 2) {
                                Text("\(vm.draftUserEstimate)")
                                    .font(.system(size: 52, weight: .light, design: .rounded))
                                    .foregroundColor(Color(hex: "1A1A2E"))
                                    .frame(minWidth: 90)
                                Text("minutes")
                                    .font(.system(size: 13, weight: .light))
                                    .tracking(1.0)
                                    .foregroundColor(Color(hex: "8A8AAA"))
                            }

                            Button(action: { vm.draftUserEstimate += 5 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(accentBlue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)

                        // Quick presets
                        HStack(spacing: 8) {
                            ForEach([15, 30, 45, 60, 90], id: \.self) { preset in
                                Button(action: { vm.draftUserEstimate = preset }) {
                                    Text("\(preset)")
                                        .font(.system(size: 13, weight: .regular))
                                        .tracking(0.5)
                                        .foregroundColor(vm.draftUserEstimate == preset ? .white : accentBlue)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(vm.draftUserEstimate == preset
                                                    ? accentBlue
                                                    : Color.white.opacity(0.3))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(accentBlue.opacity(0.3), lineWidth: 0.5)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.draftUserEstimate)
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(16)
            }
        }
        .navigationTitle("Name your task")
        .navigationBarTitleDisplayMode(.large)
        // Navigate to AI review when Continue is tapped
        .navigationDestination(isPresented: $vm.showEstimateReview) {
            EstimateReviewView()
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                PrimaryButton(
                    "Continue",
                    icon: "arrow.right.circle.fill",
                    style: canProceed ? .blue : .ghost
                ) {
                    if canProceed {
                        titleFocused = false
                        vm.proceedToEstimateReview()
                    }
                }
                .disabled(!canProceed)
                .opacity(canProceed ? 1 : 0.5)
            }
        }
        .onAppear { titleFocused = true }
    }
}
