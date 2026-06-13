import SwiftUI

struct EstimateReviewView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showManualPicker = false
    @State private var manualEstimate: Int = 30

    var body: some View {
        ZStack {
            AppGradients.estimateReview

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
                                .font(Font.dmSans(22, weight: .bold))
                                .foregroundColor(.tfDark)
                            HStack(spacing: 16) {
                                estimateRow("Your estimate", "\(vm.draftUserEstimate) min", .tfSecondary)
                                if let ai = vm.draftAISuggestion {
                                    estimateRow("AI suggests", "\(ai.suggestedMinutes) min", .tfBlue)
                                }
                                estimateRow("Selected", "\(vm.draftFinalEstimate) min", selectedColor)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    if let suggestion = vm.draftAISuggestion {
                        Text("AI RECOMMENDATION")
                            .font(Font.dmSans(13, weight: .medium))
                            .foregroundColor(.tfSecondary)
                            .kerning(0.5)
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
                                    .font(Font.dmSans(15, weight: .medium))
                                    .foregroundColor(.tfDark)
                                HStack(spacing: 20) {
                                    Button(action: { if manualEstimate > 5 { manualEstimate -= 5 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.tfBlue)
                                    }
                                    VStack(spacing: 2) {
                                        Text("\(manualEstimate)")
                                            .font(Font.dmSans(40, weight: .bold))
                                            .foregroundColor(.tfDark)
                                        Text("minutes")
                                            .font(Font.dmSans(13))
                                            .foregroundColor(.tfSecondary)
                                    }
                                    Button(action: { manualEstimate += 5 }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.tfBlue)
                                    }
                                }
                                Button(action: { vm.setManualEstimate(manualEstimate); showManualPicker = false }) {
                                    Text("Use \(manualEstimate) min")
                                        .font(Font.dmSans(15, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.tfBlue)
                                        .cornerRadius(11)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Selected summary
                    TimeFlowCard {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected estimate")
                                    .font(Font.dmSans(13))
                                    .foregroundColor(.tfSecondary)
                                Text("\(vm.draftFinalEstimate) minutes")
                                    .font(Font.dmSans(20, weight: .bold))
                                    .foregroundColor(.tfDark)
                            }
                            Spacer()
                            Text(sourceLabel)
                                .font(Font.dmSans(12, weight: .medium))
                                .foregroundColor(selectedColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Review Estimate")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                Button(action: { vm.createAndStartTask() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text("Start Timer")
                            .font(Font.dmSans(17, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.tfBlue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
        }
    }

    private var selectedColor: Color {
        switch vm.draftFinalEstimateSource {
        case .user:   return Color(hex: "059669")
        case .ai:     return .tfBlue
        case .manual: return Color(hex: "7C3AED")
        }
    }

    private var sourceLabel: String {
        switch vm.draftFinalEstimateSource {
        case .user:   return "Your Estimate"
        case .ai:     return "AI Suggestion"
        case .manual: return "Custom"
        }
    }

    private func estimateRow(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Font.dmSans(11))
                .foregroundColor(.tfSecondary)
            Text(value)
                .font(Font.dmSans(15, weight: .medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
