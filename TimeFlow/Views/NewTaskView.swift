import SwiftUI

// MARK: - Step 1: Category selection

struct NewTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pushStep2 = false
    @State private var tappedCategory: TaskCategory? = nil

    var body: some View {
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
        .background(Color.clear)
        .navigationTitle("What type of task?")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .font(Font.dmSans(17))
                    .foregroundColor(.tfSecondary)
            }
        }
        .navigationDestination(isPresented: $pushStep2) {
            NewTaskStep2View()
        }
    }

    private func categoryCard(_ cat: TaskCategory) -> some View {
        let isHighlighted = tappedCategory == cat
        return Button(action: {
            vm.draftCategory = cat
            tappedCategory = cat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                tappedCategory = nil
                pushStep2 = true
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(cat.color.opacity(0.13))
                        .frame(width: 60, height: 60)
                    Image(systemName: cat.icon)
                        .font(.system(size: 28))
                        .foregroundColor(cat.color)
                }
                Text(cat.rawValue)
                    .font(Font.dmSans(15, weight: .medium))
                    .foregroundColor(.tfDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(isHighlighted ? 0.7 : 0.35))
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cat.color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isHighlighted ? cat.color : Color.white.opacity(0.5),
                            lineWidth: isHighlighted ? 1.5 : 1
                        )
                }
            )
            .scaleEffect(isHighlighted ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 2: Name + estimate

struct NewTaskStep2View: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @FocusState private var titleFocused: Bool

    private var canProceed: Bool {
        !vm.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // ── Task name ──────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Label("Task Name", systemImage: "pencil.line")
                        .font(Font.dmSans(13, weight: .medium))
                        .foregroundColor(.tfSecondary)

                    TextField("What are you going to do?", text: $vm.draftTitle)
                        .font(Font.dmSans(17))
                        .padding(14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.35))
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                            }
                        )
                        .focused($titleFocused)
                }

                // ── Estimate stepper ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    Label("Your Estimate", systemImage: "clock")
                        .font(Font.dmSans(13, weight: .medium))
                        .foregroundColor(.tfSecondary)

                    TimeFlowCard {
                        HStack(spacing: 24) {
                            Button(action: {
                                if vm.draftUserEstimate > 5 { vm.draftUserEstimate -= 5 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(
                                        vm.draftUserEstimate > 5 ? .tfBlue : Color(.systemGray4)
                                    )
                            }
                            .disabled(vm.draftUserEstimate <= 5)

                            VStack(spacing: 2) {
                                Text("\(vm.draftUserEstimate)")
                                    .font(Font.dmSans(52, weight: .bold))
                                    .foregroundColor(.tfDark)
                                    .frame(minWidth: 90)
                                Text("minutes")
                                    .font(Font.dmSans(13))
                                    .foregroundColor(.tfSecondary)
                            }

                            Button(action: { vm.draftUserEstimate += 5 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.tfBlue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }

                    // Quick presets
                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90], id: \.self) { preset in
                            Button(action: { vm.draftUserEstimate = preset }) {
                                Text("\(preset)")
                                    .font(Font.dmSans(13, weight: .medium))
                                    .foregroundColor(vm.draftUserEstimate == preset ? .white : .tfBlue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        vm.draftUserEstimate == preset
                                            ? Color.tfBlue
                                            : Color.tfBlue.opacity(0.10)
                                    )
                                    .cornerRadius(9)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationTitle("Name your task")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $vm.showEstimateReview) {
            EstimateReviewView()
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                Button(action: {
                    if canProceed {
                        titleFocused = false
                        vm.proceedToEstimateReview()
                    }
                }) {
                    Text("Continue")
                        .font(Font.dmSans(17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(canProceed ? Color.tfBlue : Color.tfBlue.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(!canProceed)
            }
        }
        .onAppear { titleFocused = true }
    }
}
