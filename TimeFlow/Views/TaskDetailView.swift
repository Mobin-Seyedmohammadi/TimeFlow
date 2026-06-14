import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let task: TimeFlowTask

    var body: some View {
        ZStack {
        AuroraBackground()
        ScrollView {
            VStack(spacing: 20) {
                // Header
                TimeFlowCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            StatusChip(category: task.category)
                            Spacer()
                            EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
                        }
                        Text(task.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A2E"))
                        if let date = task.completedAt {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                Text(date.formatted(date: .long, time: .shortened))
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(Color(hex: "8A8AAA"))
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Time breakdown
                SectionCard(title: "Time Breakdown", icon: "clock.fill") {
                    VStack(spacing: 10) {
                        detailRow("Your original estimate", value: "\(task.userEstimateMinutes) min", color: Color.black.opacity(0.5))
                        detailRow("AI suggested", value: "\(task.aiSuggestedMinutes) min", color: .tfBlue)
                        detailRow("Final selected estimate", value: "\(task.finalEstimateMinutes) min", color: Color(hex: "7C3AED"))
                        Divider()
                        detailRow("Actual duration", value: "\(task.actualDurationMinutes ?? 0) min", color: Color(hex: "059669"), bold: true)

                        if let diff = task.estimationDifferenceMinutes {
                            detailRow(
                                "Difference",
                                value: diff >= 0 ? "+\(diff) min" : "\(diff) min",
                                color: abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue),
                                bold: true
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Visual comparison
                TimeFlowCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visual Comparison")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "8A8AAA"))

                        let maxVal = max(task.userEstimateMinutes, task.aiSuggestedMinutes, task.actualDurationMinutes ?? 1)
                        VStack(spacing: 10) {
                            barRow("Your estimate", minutes: task.userEstimateMinutes, max: maxVal, color: Color.black.opacity(0.35))
                            barRow("AI suggested", minutes: task.aiSuggestedMinutes, max: maxVal, color: .tfBlue)
                            barRow("Final estimate", minutes: task.finalEstimateMinutes, max: maxVal, color: Color(hex: "7C3AED"))
                            barRow("Actual", minutes: task.actualDurationMinutes ?? 0, max: maxVal, color: Color(hex: "059669"))
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Accuracy
                if let accuracy = task.accuracyPercentage {
                    SectionCard(title: "Accuracy", icon: "chart.bar.fill", iconColor: Color(hex: "059669")) {
                        let pct = Int(accuracy * 100)
                        VStack(spacing: 8) {
                            Text("\(pct)%")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(accuracyColor(accuracy))
                            Text(accuracyDescription(accuracy))
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "8A8AAA"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                }

                // Notes
                if !task.notes.isEmpty {
                    SectionCard(title: "Notes", icon: "note.text") {
                        Text(task.notes)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8A8AAA"))
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical, 16)
        }
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(Color(hex: "8A8AAA"))
            }
        }
    }

    private func detailRow(_ label: String, value: String, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8AAA"))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: bold ? .bold : .semibold))
                .foregroundColor(color)
        }
    }

    private func barRow(_ label: String, minutes: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "8A8AAA"))
                .frame(width: 80, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.2)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: max > 0 ? geo.size.width * (CGFloat(minutes) / CGFloat(max)) : 0, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(minutes)m")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func accuracyColor(_ ratio: Double) -> Color {
        let diff = abs(ratio - 1.0)
        if diff <= 0.05 { return Color(hex: "059669") }
        if diff <= 0.20 { return Color(hex: "D97706") }
        return .tfOrange
    }

    private func accuracyDescription(_ ratio: Double) -> String {
        let pct = Int(ratio * 100)
        if abs(pct - 100) <= 5 { return "Excellent! Almost perfectly accurate." }
        if pct > 100 { return "You used \(pct - 100)% more time than estimated." }
        return "You finished \(100 - pct)% faster than estimated."
    }
}
