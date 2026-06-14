import SwiftUI

struct EstimateReviewView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showManualPicker = false
    @State private var manualEstimate: Int = 30

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

    var body: some View {
        ZStack {
            AuroraBackground()

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
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(Color(hex: "1A1A2E"))
                            HStack(spacing: 16) {
                                estimateRow("Your estimate", "\(vm.draftUserEstimate) min", Color(hex: "8A8AAA"))
                                if let ai = vm.draftAISuggestion {
                                    estimateRow("AI suggests", "\(ai.suggestedMinutes) min", accentBlue)
                                }
                                estimateRow("Selected", "\(vm.draftFinalEstimate) min", selectedColor)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    if let suggestion = vm.draftAISuggestion {
                        Text("AI Recommendation")
                            .font(.system(size: 13, weight: .light))
                            .tracking(1.0)
                            .foregroundColor(Color(hex: "8A8AAA"))
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
                                    .font(.system(size: 15, weight: .light))
                                    .tracking(0.5)
                                    .foregroundColor(Color(hex: "1A1A2E"))
                                HStack(spacing: 20) {
                                    Button(action: { if manualEstimate > 5 { manualEstimate -= 5 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 28)).foregroundColor(accentBlue)
                                    }
                                    VStack(spacing: 2) {
                                        Text("\(manualEstimate)")
                                            .font(.system(size: 40, weight: .light, design: .rounded))
                                            .foregroundColor(Color(hex: "1A1A2E"))
                                        Text("minutes")
                                            .font(.system(size: 13, weight: .light))
                                            .tracking(0.5)
                                            .foregroundColor(Color(hex: "8A8AAA"))
                                    }
                                    Button(action: { manualEstimate += 5 }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28)).foregroundColor(accentBlue)
                                    }
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(accentBlue.opacity(0.4))
                                        .frame(height: 60)
                                        .blur(radius: 16)
                                        .padding(.horizontal, 20)

                                    Button(action: { vm.setManualEstimate(manualEstimate); showManualPicker = false }) {
                                        Text("Use \(manualEstimate) min")
                                            .font(.system(size: 15, weight: .regular))
                                            .tracking(0.5)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity).frame(height: 44)
                                            .background(accentBlue).cornerRadius(20)
                                    }
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
                                Text("Selected estimate")
                                    .font(.system(size: 13, weight: .light))
                                    .tracking(0.5)
                                    .foregroundColor(Color(hex: "8A8AAA"))
                                Text("\(vm.draftFinalEstimate) minutes")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(Color(hex: "1A1A2E"))
                            }
                            Spacer()
                            Text(sourceLabel)
                                .font(.system(size: 12, weight: .regular))
                                .tracking(0.5)
                                .foregroundColor(selectedColor)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(selectedColor.opacity(0.1))
                                        .overlay(Capsule().stroke(selectedColor.opacity(0.3), lineWidth: 1))
                                )
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
                PrimaryButton("Start Timer", icon: "timer") { vm.createAndStartTask() }
            }
        }
    }

    private var selectedColor: Color {
        switch vm.draftFinalEstimateSource {
        case .user: return Color(hex: "059669")
        case .ai: return accentBlue
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
            Text(label)
                .font(.system(size: 11, weight: .light))
                .tracking(0.5)
                .foregroundColor(Color(hex: "8A8AAA"))
            Text(value)
                .font(.system(size: 15, weight: .regular))
                .tracking(0.5)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
