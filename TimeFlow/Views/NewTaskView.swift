import SwiftUI

// MARK: - Step 1: Category selection

struct NewTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @Environment(\.dismiss) private var dismiss

    /// Drives the NavigationLink push to Step 2.
    @State private var pushStep2 = false
    /// Tracks which card was just tapped so we can briefly highlight it.
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
        .background(Color.tfBackground.ignoresSafeArea())
        .navigationTitle("What type of task?")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
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
                        .fill(cat.color.opacity(0.13))
                        .frame(width: 60, height: 60)
                    Image(systemName: cat.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(cat.color)
                }
                Text(cat.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.tfDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(isHighlighted ? cat.color.opacity(0.22) : Color.tfCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHighlighted ? cat.color : Color.black.opacity(0.07),
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("What are you going to do?", text: $vm.draftTitle)
                        .font(.system(size: 17))
                        .padding(14)
                        .background(Color.tfCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.10), lineWidth: 1)
                        )
                        .focused($titleFocused)
                }

                // ── Estimate stepper ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    Label("Your Estimate", systemImage: "clock")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

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
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(.tfDark)
                                .frame(minWidth: 90)
                            Text("minutes")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Button(action: { vm.draftUserEstimate += 5 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.tfBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    // Quick presets
                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90], id: \.self) { preset in
                            Button(action: { vm.draftUserEstimate = preset }) {
                                Text("\(preset)")
                                    .font(.system(size: 13, weight: .medium))
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
        .background(Color.tfBackground.ignoresSafeArea())
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
