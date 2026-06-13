import SwiftUI

struct EstimateReviewView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showManualPicker = false
    @State private var manualEstimate: Int = 30

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task summary header
                TimeFlowCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            StatusChip(category: vm.draftCategory)
                            Spacer()
                        }
                        Text(vm.draftTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.tfDark)
                        HStack(spacing: 16) {
                            estimateRow("Your estimate", "\(vm.draftUserEstimate) min", .secondary)
                            if let ai = vm.draftAISuggestion {
                                estimateRow("AI suggests", "\(ai.suggestedMinutes) min", .tfBlue)
                            }
                            estimateRow("Selected", "\(vm.draftFinalEstimate) min", selectedColor)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if let suggestion = vm.draftAISuggestion {
                    Text("AI Recommendation")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)

                    AISuggestionCard(
                        suggestion: suggestion,
                        userEstimate: vm.draftUserEstimate,
                        showExplanation: vm.showAIExplanation,
                        onUse: { vm.useAISuggestion(); showManualPicker = false },
                        onKeep: { vm.keepUserEstimate(); showManualPicker = false },
                        onAdjust: { manualEstimate = vm.draftFinalEstimate; showManualPicker.toggle() }
                    )
                    .padding(.horizontal, 16)
                }

                if showManualPicker {
                    TimeFlowCard {
                        VStack(spacing: 12) {
                            Text("Set Custom Estimate")
                                .font(.system(size: 15, weight: .semibold))
                            HStack(spacing: 20) {
                                Button(action: { if manualEstimate > 5 { manualEstimate -= 5 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28)).foregroundColor(.tfBlue)
                                }
                                VStack(spacing: 2) {
                                    Text("\(manualEstimate)")
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(.tfDark)
                                    Text("minutes").font(.system(size: 13)).foregroundColor(.secondary)
                                }
                                Button(action: { manualEstimate += 5 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28)).foregroundColor(.tfBlue)
                                }
                            }
                            Button(action: { vm.setManualEstimate(manualEstimate); showManualPicker = false }) {
                                Text("Use \(manualEstimate) min")
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).frame(height: 44)
                                    .background(Color.tfBlue).cornerRadius(11)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Selected summary
                TimeFlowCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24)).foregroundColor(selectedColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Selected estimate").font(.system(size: 13)).foregroundColor(.secondary)
                            Text("\(vm.draftFinalEstimate) minutes").font(.system(size: 20, weight: .bold)).foregroundColor(.tfDark)
                        }
                        Spacer()
                        Text(sourceLabel)
                            .font(.system(size: 12, weight: .medium)).foregroundColor(selectedColor)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(selectedColor.opacity(0.1)).cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 100)
            }
            .padding(.vertical, 16)
        }
        .background(Color.tfBackground.ignoresSafeArea())
        .navigationTitle("Review Estimate")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                PrimaryButton("Start Timer", icon: "timer") { vm.createAndStartTask() }
            }
        }
    }

    private var selectedColor: Color {
        switch vm.draftFinalEstimateSource {
        case .user: return Color(hex: "059669")
        case .ai: return .tfBlue
        case .manual: return Color(hex: "7C3AED")
        }
    }

    private var sourceLabel: String {
        switch vm.draftFinalEstimateSource {
        case .user: return "Your Estimate"
        case .ai: return "AI Suggestion"
        case .manual: return "Custom"
        }
    }

    private func estimateRow(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
