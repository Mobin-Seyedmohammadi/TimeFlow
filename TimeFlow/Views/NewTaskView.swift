import SwiftUI

struct NewTaskView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    private var canProceed: Bool {
        !vm.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty && vm.draftUserEstimate > 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Task name
                VStack(alignment: .leading, spacing: 8) {
                    Label("Task Name", systemImage: "pencil.line")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("What are you going to do?", text: $vm.draftTitle)
                        .font(.system(size: 17))
                        .padding(14)
                        .background(Color.tfCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.1), lineWidth: 1))
                        .focused($titleFocused)
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Label("Category", systemImage: "tag.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(TaskCategory.allCases) { cat in
                            categoryButton(cat)
                        }
                    }
                }

                // Estimate
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your Estimate", systemImage: "clock")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack {
                        Text("How long do you think this will take?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    HStack(spacing: 16) {
                        // Minus
                        Button(action: {
                            if vm.draftUserEstimate > 5 { vm.draftUserEstimate -= 5 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.tfBlue)
                        }
                        .disabled(vm.draftUserEstimate <= 5)

                        VStack(spacing: 2) {
                            Text("\(vm.draftUserEstimate)")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.tfDark)
                                .frame(minWidth: 70)
                            Text("minutes")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        // Plus
                        Button(action: { vm.draftUserEstimate += 5 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.tfBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Quick presets
                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90], id: \.self) { preset in
                            Button(action: { vm.draftUserEstimate = preset }) {
                                Text("\(preset)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(vm.draftUserEstimate == preset ? .white : .tfBlue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(vm.draftUserEstimate == preset ? Color.tfBlue : Color.tfBlue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Notes (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notes (optional)", systemImage: "note.text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("Any extra context...", text: $vm.draftNotes, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(3, reservesSpace: true)
                        .padding(14)
                        .background(Color.tfCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.1), lineWidth: 1))
                }

                Spacer(minLength: 80)
            }
            .padding(16)
        }
        .background(Color.tfBackground.ignoresSafeArea())
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
            }
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

    private func categoryButton(_ cat: TaskCategory) -> some View {
        let isSelected = vm.draftCategory == cat
        return Button(action: { vm.draftCategory = cat }) {
            VStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : cat.color)
                Text(cat.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : .tfDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(isSelected ? cat.color : Color.tfCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? cat.color : Color.black.opacity(0.08), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}
