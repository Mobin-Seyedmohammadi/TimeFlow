import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var vm: TimeFlowViewModel

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

            if vm.completedTasks.isEmpty {
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

                            // Regression Analysis section
                            regressionSection
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

    // MARK: - Regression Analysis

    @ViewBuilder
    private var regressionSection: some View {
        // Show categories that have n >= 2 regression stats
        let regressionCategories = TaskCategory.allCases.compactMap { cat -> (TaskCategory, RegressionStats)? in
            guard let stats = vm.categoryStats[cat.rawValue], stats.n >= 2 else { return nil }
            return (cat, stats)
        }

        if !regressionCategories.isEmpty {
            SectionCard(title: "AI Pattern Analysis", icon: "function", iconColor: .tfBlue) {
                VStack(spacing: 14) {
                    ForEach(Array(regressionCategories.enumerated()), id: \.offset) { index, pair in
                        let (category, stats) = pair
                        if index > 0 { Divider() }
                        regressionRow(category: category, stats: stats)
                    }

                    // Show categories with exactly 1 task
                    let singleCategories = TaskCategory.allCases.filter { cat in
                        vm.categoryStats[cat.rawValue]?.n == 1
                    }
                    if !singleCategories.isEmpty {
                        if !regressionCategories.isEmpty { Divider() }
                        ForEach(singleCategories) { cat in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13))
                                    .foregroundColor(cat.color)
                                    .frame(width: 18)
                                Text(cat.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.tfDark)
                                Spacer()
                                Text("1 task — complete more for pattern analysis")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func regressionRow(category: TaskCategory, stats: RegressionStats) -> some View {
        let n    = stats.n
        let sumX = stats.sumX
        let sumY = stats.sumY
        let Sxx  = stats.sumXX - (sumX * sumX) / n
        let Sxy  = stats.sumXY - (sumX * sumY) / n
        let Syy  = stats.sumYY - (stats.sumY * stats.sumY) / n

        // Slope: for every 10 min planned → beta1*10 min actual
        let beta1: Double = Sxx > 1e-9 ? (Sxy / Sxx) : (sumX > 1e-9 ? sumY / sumX : 1.0)
        let per10 = max(1, Int((beta1 * 10).rounded()))

        // R² = Sxy² / (Sxx * Syy), clamped to [0, 1]
        let r2: Double
        if Sxx > 1e-9 && Syy > 1e-9 {
            r2 = min(1.0, max(0.0, (Sxy * Sxy) / (Sxx * Syy)))
        } else {
            r2 = 0.0
        }
        let accuracyPct = Int((r2 * 100).rounded())

        // Bias at the average estimate level
        let biasRaw = sumX > 1e-9 ? ((sumY / sumX) - 1.0) * 100 : 0.0
        let biasPct = Int(biasRaw.rounded())

        let biasText: String
        if abs(biasPct) <= 5 {
            biasText = "Estimates are accurate on average"
        } else if biasPct > 0 {
            biasText = "Tends to underestimate by ~\(biasPct)%"
        } else {
            biasText = "Tends to overestimate by ~\(abs(biasPct))%"
        }

        let biasColor: Color = abs(biasPct) <= 5 ? Color(hex: "059669") : (biasPct > 0 ? .tfOrange : .tfBlue)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tfDark)
                Spacer()
                Text("Based on \(Int(n)) tasks")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 0) {
                regressionStat(
                    label: "Per 10 min planned",
                    value: "\(per10) min actual",
                    color: .tfDark
                )
                Divider().frame(height: 34)
                regressionStat(
                    label: "Model fit (R²)",
                    value: "\(accuracyPct)%",
                    color: accuracyPct >= 70 ? Color(hex: "059669") : Color(hex: "D97706")
                )
            }

            Text(biasText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(biasColor)
        }
    }

    private func regressionStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    // MARK: - Empty State

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

    // MARK: - Insight Cards

    private func insightCard(_ insight: Insight) -> some View {
        let accentColor: Color = {
            switch insight.type {
            case .improvement:    return Color(hex: "059669")
            case .pattern:        return .tfOrange
            case .recommendation: return Color(hex: "7C3AED")
            case .accuracy:       return .tfBlue
            case .aiNote:         return .secondary
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
            case .improvement:    return "Progress"
            case .pattern:        return "Pattern"
            case .recommendation: return "Tip"
            case .accuracy:       return "Accuracy"
            case .aiNote:         return "AI Note"
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

    // MARK: - Category Stats (for "By Category" row list)

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
                .font(.system(size: 14))
                .foregroundColor(.tfDark)

            Spacer()

            Text("\(stat.count) task\(stat.count == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            let pct = Int(stat.avgDiffPct.rounded())
            Text(pct >= 0 ? "+\(pct)%" : "\(pct)%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(abs(pct) <= 5 ? Color(hex: "059669") : (pct > 0 ? .tfOrange : .tfBlue))
                .frame(width: 46, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
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
