import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    private let accentBlue = Color(red: 0.133, green: 0, blue: 1)

    var body: some View {
        ZStack {
            AuroraBackground()

            if vm.completedTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {

                        // 1. Your Overview
                        TimeFlowCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Overview")
                                    .font(.system(size: 15, weight: .light))
                                    .tracking(1.0)
                                    .foregroundColor(Color(hex: "1A1A2E"))

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
                        SectionCard(title: "By Category", icon: "chart.bar.fill", iconColor: accentBlue) {
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

                        // 3. Overall accuracy/pattern (only when ≥ 3 tasks)
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
                .foregroundColor(Color(hex: "8A8AAA").opacity(0.5))
            Text("Insights will appear soon")
                .font(.system(size: 18, weight: .light))
                .tracking(0.5)
                .foregroundColor(Color(hex: "1A1A2E"))
            Text("Complete tasks to see your personal time estimation patterns.")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(hex: "4A4A6A"))
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
            case .accuracy:       return accentBlue
            case .aiNote:         return Color(hex: "8A8AAA")
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
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "1A1A2E"))
                    Text(insight.message)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "4A4A6A"))
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
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(hex: "1A1A2E"))

            Spacer()

            Text("\(stat.count) task\(stat.count == 1 ? "" : "s")")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(Color(hex: "8A8AAA"))

            let pct = Int(stat.avgDiffPct.rounded())
            Text(pct >= 0 ? "+\(pct)%" : "\(pct)%")
                .font(.system(size: 12, weight: .regular))
                .tracking(0.5)
                .foregroundColor(abs(pct) <= 5 ? Color(hex: "059669") : (pct > 0 ? .tfOrange : accentBlue))
                .frame(width: 46, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(Color(hex: "8A8AAA").opacity(0.5))
        }
    }

    private func statBlock(_ value: String, label: String, color: Color = Color(hex: "1A1A2E")) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .light))
                .tracking(0.5)
                .foregroundColor(Color(hex: "8A8AAA"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
