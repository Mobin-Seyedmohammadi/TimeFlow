import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

            if vm.completedTasks.isEmpty && vm.insights.allSatisfy({ $0.type == .aiNote }) {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header note
                        HStack(spacing: 8) {
                            Image(systemName: "cpu")
                                .foregroundColor(.tfBlue)
                                .font(.system(size: 14))
                            Text("Insights are generated from your completed tasks. The more you complete, the better they get.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.tfBlue.opacity(0.06))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)

                        // Stats overview
                        if !vm.completedTasks.isEmpty {
                            TimeFlowCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Your Overview")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.tfDark)

                                    HStack(spacing: 0) {
                                        statBlock("\(vm.completedTasks.count)", label: "Tasks Done")
                                        Divider().frame(height: 40)
                                        let underCount = vm.completedTasks.filter { ($0.estimationDifferenceMinutes ?? 0) > 3 }.count
                                        statBlock("\(underCount)", label: "Underestimated", color: .tfOrange)
                                        Divider().frame(height: 40)
                                        let accurateCount = vm.completedTasks.filter { abs($0.estimationDifferenceMinutes ?? 99) <= 3 }.count
                                        statBlock("\(accurateCount)", label: "Accurate", color: Color(hex: "059669"))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            // Category breakdown
                            SectionCard(title: "By Category", icon: "chart.bar.fill", iconColor: .tfBlue) {
                                VStack(spacing: 10) {
                                    ForEach(categoryStats(), id: \.category.id) { stat in
                                        categoryRow(stat)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Insight cards
                        ForEach(vm.insights) { insight in
                            insightCard(insight)
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Insights will appear soon")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.tfDark)
            Text("Complete tasks to see your personal time estimation patterns.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func insightCard(_ insight: Insight) -> some View {
        let accentColor: Color = {
            switch insight.type {
            case .improvement: return Color(hex: "059669")
            case .pattern: return .tfOrange
            case .recommendation: return Color(hex: "7C3AED")
            case .accuracy: return .tfBlue
            case .aiNote: return .secondary
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
                    HStack {
                        Text(insight.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.tfDark)
                        Spacer()
                        typeLabel(insight.type, color: accentColor)
                    }
                    Text(insight.message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func typeLabel(_ type: InsightType, color: Color) -> some View {
        let label: String = {
            switch type {
            case .improvement: return "Progress"
            case .pattern: return "Pattern"
            case .recommendation: return "Tip"
            case .accuracy: return "Accuracy"
            case .aiNote: return "AI Note"
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }

    private struct CategoryStat {
        let category: TaskCategory
        let count: Int
        let avgDiffMinutes: Double
    }

    private func categoryStats() -> [CategoryStat] {
        var dict: [TaskCategory: [TimeFlowTask]] = [:]
        for task in vm.completedTasks {
            dict[task.category, default: []].append(task)
        }
        return dict.map { element in
            let diffs = element.value.compactMap { $0.estimationDifferenceMinutes.map { Double($0) } }
            let avg = diffs.isEmpty ? 0 : diffs.reduce(0, +) / Double(diffs.count)
            return CategoryStat(category: element.key, count: element.value.count, avgDiffMinutes: avg)
        }
        .sorted { $0.count > $1.count }
    }

    private func categoryRow(_ stat: CategoryStat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: stat.category.icon)
                .font(.system(size: 14))
                .foregroundColor(stat.category.color)
                .frame(width: 20)

            Text(stat.category.rawValue)
                .font(.system(size: 14))
                .foregroundColor(.tfDark)

            Spacer()

            Text("\(stat.count) task\(stat.count == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            let diff = stat.avgDiffMinutes
            Text(diff >= 0 ? "+\(Int(diff)) min avg" : "\(Int(diff)) min avg")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue))
                .frame(width: 80, alignment: .trailing)
        }
    }

    private func statBlock(_ value: String, label: String, color: Color = .tfDark) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
