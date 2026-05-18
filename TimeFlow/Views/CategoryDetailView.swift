import SwiftUI

struct CategoryDetailView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    let category: TaskCategory

    // Newest first (matches History screen)
    private var tasks: [TimeFlowTask] {
        vm.completedTasks.filter { $0.category == category && $0.actualDurationMinutes != nil }
    }

    // Oldest first — used for chart and trend
    private var tasksChronological: [TimeFlowTask] { Array(tasks.reversed()) }

    private var avgPct: Double {
        let pcts = tasks.compactMap { t -> Double? in
            guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
            return Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100
        }
        guard !pcts.isEmpty else { return 0 }
        return pcts.reduce(0, +) / Double(pcts.count)
    }

    private var avgMinDiff: Double {
        let diffs = tasks.compactMap { t -> Double? in
            guard let a = t.actualDurationMinutes else { return nil }
            return Double(a - t.finalEstimateMinutes)
        }
        guard !diffs.isEmpty else { return 0 }
        return diffs.reduce(0, +) / Double(diffs.count)
    }

    private var bestTask: TimeFlowTask? {
        tasks.min { abs($0.estimationDifferenceMinutes ?? Int.max) < abs($1.estimationDifferenceMinutes ?? Int.max) }
    }

    private var worstTask: TimeFlowTask? {
        tasks.max { abs($0.estimationDifferenceMinutes ?? 0) < abs($1.estimationDifferenceMinutes ?? 0) }
    }

    private var maxBarMinutes: Int {
        tasksChronological.compactMap { t -> Int? in
            guard let a = t.actualDurationMinutes else { return nil }
            return max(t.finalEstimateMinutes, a)
        }.max() ?? 1
    }

    private func scaledBarHeight(_ minutes: Int, chartHeight: CGFloat) -> CGFloat {
        guard maxBarMinutes > 0 else { return 4 }
        return max(4, CGFloat(minutes) / CGFloat(maxBarMinutes) * chartHeight)
    }

    private func actualBarColor(_ task: TimeFlowTask) -> Color {
        guard let diff = task.estimationDifferenceMinutes else { return .secondary }
        if abs(diff) <= 3 { return Color(hex: "059669") }
        return diff > 0 ? Color.tfOrange : Color.tfBlue.opacity(0.45)
    }

    // Trend: compare avg abs % error of first half vs second half (chronological)
    private var trend: (text: String, icon: String, color: Color) {
        guard tasksChronological.count >= 4 else {
            let needed = max(0, 4 - tasksChronological.count)
            return ("Complete \(needed) more task\(needed == 1 ? "" : "s") in this category to see a trend.", "clock", .secondary)
        }
        let half = tasksChronological.count / 2
        let older = Array(tasksChronological.prefix(half))
        let newer = Array(tasksChronological.suffix(half))

        func avgAbsError(_ ts: [TimeFlowTask]) -> Double {
            let errs = ts.compactMap { t -> Double? in
                guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                return abs(Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100)
            }
            return errs.isEmpty ? 0 : errs.reduce(0, +) / Double(errs.count)
        }

        let delta = avgAbsError(newer) - avgAbsError(older) // negative = improving
        if delta < -5 {
            return ("Improving — your recent \(category.rawValue.lowercased()) estimates are more accurate than your earlier ones.", "arrow.up.right.circle.fill", Color(hex: "059669"))
        } else if delta > 5 {
            return ("Getting less accurate — your recent \(category.rawValue.lowercased()) estimates have higher error than your earlier ones.", "arrow.down.right.circle.fill", .tfOrange)
        } else {
            return ("Stable — your estimation accuracy for this category is consistent over time.", "arrow.right.circle.fill", .secondary)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                if tasks.count >= 2 { barChartCard }
                trendCard
                if tasks.count >= 2 { notableTasksCard }
                taskListCard
                Spacer(minLength: 20)
            }
            .padding(.vertical, 8)
        }
        .background(Color.tfBackground.ignoresSafeArea())
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        TimeFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(category.color.opacity(0.12)).frame(width: 48, height: 48)
                        Image(systemName: category.icon)
                            .font(.system(size: 22))
                            .foregroundColor(category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.tfDark)
                        Text("\(tasks.count) completed task\(tasks.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 0) {
                    let pctInt = Int(avgPct.rounded())
                    let pctColor: Color = abs(pctInt) <= 5 ? Color(hex: "059669") : (pctInt > 0 ? .tfOrange : .tfBlue)
                    statBlock(
                        value: pctInt >= 0 ? "+\(pctInt)%" : "\(pctInt)%",
                        label: pctInt > 0 ? "avg underestimate" : (pctInt < 0 ? "avg overestimate" : "avg accuracy"),
                        color: pctColor
                    )
                    Divider().frame(height: 40)
                    let minInt = Int(avgMinDiff.rounded())
                    statBlock(
                        value: minInt >= 0 ? "+\(minInt) min" : "\(minInt) min",
                        label: "avg difference",
                        color: abs(minInt) <= 3 ? Color(hex: "059669") : (minInt > 0 ? .tfOrange : .tfBlue)
                    )
                    Divider().frame(height: 40)
                    statBlock(value: "\(tasks.count)", label: "tasks done", color: .tfDark)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bar Chart

    private var barChartCard: some View {
        SectionCard(title: "Estimated vs Actual", icon: "chart.bar.fill", iconColor: category.color) {
            VStack(alignment: .leading, spacing: 10) {
                let chartH: CGFloat = 150

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(Array(tasksChronological.enumerated()), id: \.offset) { index, task in
                            let estH = scaledBarHeight(task.finalEstimateMinutes, chartHeight: chartH)
                            let actH = scaledBarHeight(task.actualDurationMinutes ?? 0, chartHeight: chartH)
                            VStack(spacing: 4) {
                                HStack(alignment: .bottom, spacing: 3) {
                                    // Estimate bar
                                    VStack(spacing: 2) {
                                        Text("\(task.finalEstimateMinutes)")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                            .opacity(estH > 22 ? 1 : 0)
                                        Spacer(minLength: 0)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.tfBlue.opacity(0.8))
                                            .frame(width: 22, height: estH)
                                    }
                                    .frame(height: chartH)

                                    // Actual bar
                                    VStack(spacing: 2) {
                                        Text("\(task.actualDurationMinutes ?? 0)")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                            .opacity(actH > 22 ? 1 : 0)
                                        Spacer(minLength: 0)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(actualBarColor(task))
                                            .frame(width: 22, height: actH)
                                    }
                                    .frame(height: chartH)
                                }
                                Text("#\(index + 1)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 12)
                }

                HStack(spacing: 14) {
                    legendDot(color: Color.tfBlue.opacity(0.8), label: "Estimated")
                    legendDot(color: Color(hex: "059669"), label: "Accurate")
                    legendDot(color: Color.tfOrange, label: "Over")
                    legendDot(color: Color.tfBlue.opacity(0.45), label: "Under")
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 10)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    // MARK: - Trend

    private var trendCard: some View {
        let t = trend
        return SectionCard(title: "Trend", icon: t.icon, iconColor: t.color) {
            Text(t.text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Notable Tasks

    private var notableTasksCard: some View {
        SectionCard(title: "Notable Tasks", icon: "star.fill", iconColor: Color(hex: "D97706")) {
            VStack(spacing: 12) {
                if let best = bestTask {
                    highlightRow(badge: "Most Accurate", task: best, badgeColor: Color(hex: "059669"))
                }
                if let worst = worstTask, worst.id != bestTask?.id {
                    Divider()
                    highlightRow(badge: "Largest Error", task: worst, badgeColor: .tfOrange)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func highlightRow(badge: String, task: TimeFlowTask, badgeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(badge)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badgeColor)
                .textCase(.uppercase)
            Text(task.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.tfDark)
                .lineLimit(1)
            HStack(spacing: 16) {
                miniStat("Estimated", "\(task.finalEstimateMinutes) min")
                miniStat("Actual", "\(task.actualDurationMinutes ?? 0) min")
                if let diff = task.estimationDifferenceMinutes {
                    miniStat(
                        "Diff",
                        diff >= 0 ? "+\(diff) min" : "\(diff) min",
                        color: abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue)
                    )
                }
            }
        }
    }

    // MARK: - All Tasks

    private var taskListCard: some View {
        SectionCard(title: "All Tasks", icon: "list.bullet", iconColor: .secondary) {
            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    if index > 0 { Divider().padding(.vertical, 8) }
                    taskRow(task)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func taskRow(_ task: TimeFlowTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tfDark)
                    .lineLimit(1)
                Spacer()
                EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
            }
            HStack(spacing: 16) {
                miniStat("Estimated", "\(task.finalEstimateMinutes) min")
                miniStat("Actual", "\(task.actualDurationMinutes ?? 0) min")
                if let diff = task.estimationDifferenceMinutes {
                    miniStat(
                        "Diff",
                        diff >= 0 ? "+\(diff) min" : "\(diff) min",
                        color: abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue)
                    )
                }
                if task.finalEstimateMinutes > 0, let a = task.actualDurationMinutes {
                    let pct = Int(Double(a - task.finalEstimateMinutes) / Double(task.finalEstimateMinutes) * 100)
                    miniStat(
                        "% off",
                        pct >= 0 ? "+\(pct)%" : "\(pct)%",
                        color: abs(pct) <= 5 ? Color(hex: "059669") : (pct > 0 ? .tfOrange : .tfBlue)
                    )
                }
            }
            if let date = task.completedAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func miniStat(_ label: String, _ value: String, color: Color = .tfDark) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(color)
        }
    }
}
