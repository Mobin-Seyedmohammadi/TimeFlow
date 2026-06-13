import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    var body: some View {
        ZStack {
            AppGradients.insights

            if vm.completedTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {

                        // 1. Your Overview
                        TimeFlowCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("YOUR OVERVIEW")
                                    .font(Font.dmSans(13, weight: .medium))
                                    .foregroundColor(.tfSecondary)
                                    .kerning(0.5)

                                HStack(spacing: 0) {
                                    statBlock("\(vm.completedTasks.count)", label: "Tasks Done")
                                    Divider().frame(height: 40)
                                    let underCount = vm.completedTasks.filter {
                                        ($0.estimationDifferenceMinutes ?? 0) > 3
                                    }.count
                                    statBlock("\(underCount)", label: "Underestimated", color: .tfOrange)
                                    Divider().frame(height: 40)
                                    let accurateCount = vm.completedTasks.filter {
                                        abs($0.estimationDifferenceMinutes ?? 99) <= 3
                                    }.count
                                    statBlock("\(accurateCount)", label: "Accurate", color: Color(hex: "059669"))
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // 2. By Category
                        SectionCard(title: "By Category", icon: "chart.bar.fill", iconColor: .tfBlue) {
                            VStack(spacing: 10) {
                                ForEach(categoryStatsRows(), id: \.category.id) { stat in
                                    NavigationLink {
                                        CategoryDetailView(category: stat.category)
                                    } label: {
                                        categoryRow(stat)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // 3. Overall accuracy/pattern
                        if let overall = vm.insights.first(where: {
                            $0.title == "Overall Pattern" || $0.title == "Overall Accuracy"
                        }) {
                            insightCard(overall)
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.tfSecondary.opacity(0.5))
            Text("Insights will appear soon")
                .font(Font.dmSans(18, weight: .bold))
                .foregroundColor(.tfDark)
            Text("Complete tasks to see your personal time estimation patterns.")
                .font(Font.dmSans(15))
                .foregroundColor(.tfSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Overall insight card

    private func insightCard(_ insight: Insight) -> some View {
        let accentColor: Color = {
            switch insight.type {
            case .improvement:    return Color(hex: "059669")
            case .pattern:        return .tfOrange
            case .recommendation: return Color(hex: "7C3AED")
            case .accuracy:       return .tfBlue
            case .aiNote:         return .tfSecondary
            }
        }()

        return TimeFlowCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: insight.icon)
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(insight.title)
                        .font(Font.dmSans(17, weight: .bold))
                        .foregroundColor(.tfDark)
                    Text(insight.message)
                        .font(Font.dmSans(15))
                        .foregroundColor(.tfSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Category Stats

    private struct CategoryStatRow {
        let category: TaskCategory
        let count: Int
        let avgDiffPct: Double
    }

    private func categoryStatsRows() -> [CategoryStatRow] {
        var dict: [TaskCategory: [TimeFlowTask]] = [:]
        for task in vm.completedTasks where task.actualDurationMinutes != nil {
            dict[task.category, default: []].append(task)
        }
        return dict.map { element in
            let pcts = element.value.compactMap { t -> Double? in
                guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                return Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100
            }
            let avg = pcts.isEmpty ? 0.0 : pcts.reduce(0, +) / Double(pcts.count)
            return CategoryStatRow(category: element.key, count: element.value.count, avgDiffPct: avg)
        }
        .sorted { $0.count > $1.count }
    }

    private func categoryRow(_ stat: CategoryStatRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: stat.category.icon)
                .font(.system(size: 14))
                .foregroundColor(stat.category.color)
                .frame(width: 20)

            Text(stat.category.rawValue)
                .font(Font.dmSans(15))
                .foregroundColor(.tfDark)

            Spacer()

            Text("\(stat.count) task\(stat.count == 1 ? "" : "s")")
                .font(Font.dmSans(13))
                .foregroundColor(.tfSecondary)

            let pct = Int(stat.avgDiffPct.rounded())
            Text(pct >= 0 ? "+\(pct)%" : "\(pct)%")
                .font(Font.dmSans(13, weight: .medium))
                .foregroundColor(abs(pct) <= 5 ? Color(hex: "059669") : (pct > 0 ? .tfOrange : .tfBlue))
                .frame(width: 46, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.tfSecondary.opacity(0.5))
        }
    }

    private func statBlock(_ value: String, label: String, color: Color = .tfDark) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Font.dmSans(28, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(Font.dmSans(11))
                .foregroundColor(.tfSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
