import SwiftUI

struct CategoryDetailView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    let category: TaskCategory

    // Newest first (matches History screen)
    private var tasks: [TimeFlowTask] {
        vm.completedTasks.filter { $0.category == category && $0.actualDurationMinutes != nil }
    }

    // Oldest first — used for charts and trend
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

    // Half/half trend comparison
    private var trend: (text: String, icon: String, color: Color) {
        guard tasksChronological.count >= 4 else {
            let needed = max(0, 4 - tasksChronological.count)
            return ("Complete \(needed) more task\(needed == 1 ? "" : "s") in this category to see a trend.", "clock", .secondary)
        }
        let half  = tasksChronological.count / 2
        let older = Array(tasksChronological.prefix(half))
        let newer = Array(tasksChronological.suffix(half))

        func avgAbsError(_ ts: [TimeFlowTask]) -> Double {
            let errs = ts.compactMap { t -> Double? in
                guard let a = t.actualDurationMinutes, t.finalEstimateMinutes > 0 else { return nil }
                return abs(Double(a - t.finalEstimateMinutes) / Double(t.finalEstimateMinutes) * 100)
            }
            return errs.isEmpty ? 0 : errs.reduce(0, +) / Double(errs.count)
        }

        let delta = avgAbsError(newer) - avgAbsError(older)
        if delta < -5 {
            return ("Improving — your recent \(category.rawValue.lowercased()) estimates are more accurate than your earlier ones.", "arrow.up.right.circle.fill", Color(hex: "059669"))
        } else if delta > 5 {
            return ("Getting less accurate — your recent \(category.rawValue.lowercased()) estimates have higher error than your earlier ones.", "arrow.down.right.circle.fill", .tfOrange)
        } else {
            return ("Stable — your estimation accuracy for this category is consistent over time.", "arrow.right.circle.fill", .secondary)
        }
    }

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    if tasks.count >= 2 {
                        scatterChartCard      // absolute-error scatter
                        regressionChartCard   // fitted model (estimate → actual)
                    }
                    trendCard
                    if tasks.count >= 2 { notableTasksCard }
                    taskListCard
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary card

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
                            .foregroundColor(Color(hex: "1A1A2E"))
                        Text("\(tasks.count) completed task\(tasks.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8A8AAA"))
                    }
                }

                Divider()

                HStack(spacing: 0) {
                    let pctInt   = Int(avgPct.rounded())
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
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA")).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // =========================================================================
    // MARK: - Scatter Chart  (absolute estimation error over time)
    // =========================================================================

    private struct ErrorPoint {
        let taskNumber: Int        // 1-based, chronological
        let signedErrorPct: Double // positive = under, negative = over (drives dot colour)
        let absErrorPct: Double    // absolute value (drives Y position)
    }

    private var errorPoints: [ErrorPoint] {
        tasksChronological.enumerated().compactMap { idx, task -> ErrorPoint? in
            guard let actual = task.actualDurationMinutes, task.finalEstimateMinutes > 0 else { return nil }
            let signed = Double(actual - task.finalEstimateMinutes) / Double(task.finalEstimateMinutes) * 100
            return ErrorPoint(taskNumber: idx + 1, signedErrorPct: signed, absErrorPct: abs(signed))
        }
    }

    // OLS regression of (taskNumber → absErrorPct) — used for the temporal trend line
    private var errorTrendLine: (slope: Double, intercept: Double)? {
        let pts = errorPoints
        guard pts.count >= 2 else { return nil }
        let n     = Double(pts.count)
        let xs    = pts.map { Double($0.taskNumber) }
        let ys    = pts.map { $0.absErrorPct }
        let sumX  = xs.reduce(0, +),  sumY  = ys.reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let sumXY = zip(xs, ys).map { $0 * $1 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        guard abs(denom) > 1e-9 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        return (slope, (sumY - slope * sumX) / n)
    }

    private var scatterSummaryText: String {
        guard let reg = errorTrendLine else { return "Complete more tasks to see a trend." }
        if reg.slope < -1.0 { return "You are improving — your estimation errors are getting smaller over time." }
        if reg.slope >  1.0 { return "Your estimation errors are increasing. Try to reflect more after each task." }
        return "Your estimation accuracy is stable."
    }

    // Dot colour is always driven by the SIGNED error (direction still matters)
    private func dotColor(for signedError: Double) -> Color {
        if signedError >  10 { return Color(hex: "FF4200") } // underestimated — orange
        if signedError < -10 { return Color(hex: "7C3AED") } // overestimated  — purple
        return Color(hex: "2B00FF")                           // accurate       — blue
    }

    // Y axis ceiling: at least 50%, extended in 25% steps to contain data + headroom
    private func scatterYMax(pts: [ErrorPoint]) -> Double {
        let maxAbs = pts.map { $0.absErrorPct }.max() ?? 0
        return max(50.0, ceil((maxAbs * 1.15) / 25.0) * 25.0)
    }

    private func drawScatterChart(context: inout GraphicsContext, size: CGSize, pts: [ErrorPoint]) {
        let leftPad:   CGFloat = 52
        let rightPad:  CGFloat = 12
        let topPad:    CGFloat = 14
        let bottomPad: CGFloat = 26

        let chartW = size.width  - leftPad - rightPad
        let chartH = size.height - topPad  - bottomPad
        guard chartW > 0, chartH > 0 else { return }

        let yMax = scatterYMax(pts: pts)

        // Coordinate helpers  (Y range: 0 at bottom → yMax at top)
        func sx(_ n: Int) -> CGFloat {
            guard pts.count > 1 else { return leftPad + chartW / 2 }
            return leftPad + CGFloat(n - 1) / CGFloat(pts.count - 1) * chartW
        }
        func sy(_ pct: Double) -> CGFloat {
            topPad + CGFloat(1.0 - min(max(pct, 0), yMax) / yMax) * chartH
        }

        // ── 1. Grid lines + Y-axis labels ────────────────────────────────────
        var yLabels: [Double] = [0, 25, 50]
        if yMax > 65 { yLabels.append(75) }
        if yMax > 90 { yLabels.append(100) }

        for yVal in yLabels {
            guard yVal <= yMax else { continue }
            let screenY = sy(yVal)
            let isZero  = yVal == 0

            var grid = Path()
            grid.move(to: CGPoint(x: leftPad, y: screenY))
            grid.addLine(to: CGPoint(x: leftPad + chartW, y: screenY))
            context.stroke(grid,
                           with: .color(isZero ? Color(white: 0.50) : Color(white: 0.75, opacity: 0.55)),
                           style: StrokeStyle(lineWidth: isZero ? 1.5 : 0.7))

            let labelStr = yVal == 0 ? "0%" : "+\(Int(yVal))%"
            context.draw(
                Text(labelStr)
                    .font(.system(size: 9))
                    .foregroundColor(isZero ? Color(white: 0.35) : Color(white: 0.55)),
                at: CGPoint(x: leftPad - 5, y: screenY), anchor: .trailing)

            if isZero {
                context.draw(
                    Text("Perfect")
                        .font(.system(size: 8))
                        .foregroundColor(Color(white: 0.60)),
                    at: CGPoint(x: leftPad + chartW - 2, y: screenY - 9), anchor: .trailing)
            }
        }

        // ── 2. Connecting line ────────────────────────────────────────────────
        if pts.count > 1 {
            var line = Path()
            line.move(to: CGPoint(x: sx(pts[0].taskNumber), y: sy(pts[0].absErrorPct)))
            for pt in pts.dropFirst() {
                line.addLine(to: CGPoint(x: sx(pt.taskNumber), y: sy(pt.absErrorPct)))
            }
            context.stroke(line, with: .color(Color(white: 0.6, opacity: 0.45)),
                           style: StrokeStyle(lineWidth: 1.2))
        }

        // ── 3. Trend line (dashed — regression of absError vs taskNumber) ─────
        if let reg = errorTrendLine, pts.count >= 2 {
            let x1 = pts.first!.taskNumber,  x2 = pts.last!.taskNumber
            let y1 = max(0, reg.slope * Double(x1) + reg.intercept)
            let y2 = max(0, reg.slope * Double(x2) + reg.intercept)
            var trendPath = Path()
            trendPath.move(to: CGPoint(x: sx(x1), y: sy(y1)))
            trendPath.addLine(to: CGPoint(x: sx(x2), y: sy(y2)))
            context.stroke(trendPath,
                           with: .color(Color(white: 0.40, opacity: 0.80)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }

        // ── 4. Data points ────────────────────────────────────────────────────
        let dotR: CGFloat = 6
        for pt in pts {
            let center  = CGPoint(x: sx(pt.taskNumber), y: sy(pt.absErrorPct))
            let dotRect = CGRect(x: center.x - dotR, y: center.y - dotR,
                                 width: dotR * 2, height: dotR * 2)
            let dotPath = Path(ellipseIn: dotRect)
            context.fill(dotPath, with: .color(dotColor(for: pt.signedErrorPct)))
            context.stroke(dotPath, with: .color(.white), style: StrokeStyle(lineWidth: 1.5))
        }

        // ── 5. X-axis labels ──────────────────────────────────────────────────
        let maxLabels = 8
        let step = max(1, Int(ceil(Double(pts.count) / Double(maxLabels))))
        for (i, pt) in pts.enumerated() {
            guard i % step == 0 || i == pts.count - 1 else { continue }
            context.draw(
                Text("#\(pt.taskNumber)")
                    .font(.system(size: 9))
                    .foregroundColor(Color(white: 0.55)),
                at: CGPoint(x: sx(pt.taskNumber), y: topPad + chartH + 5), anchor: .top)
        }
    }

    private var scatterChartCard: some View {
        SectionCard(title: "How accurate are you?", icon: "chart.xyaxis.line", iconColor: category.color) {
            VStack(alignment: .leading, spacing: 12) {
                let pts = errorPoints
                if pts.isEmpty {
                    Text("No data yet.")
                        .font(.system(size: 14)).foregroundColor(Color(hex: "8A8AAA"))
                        .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 40)
                } else {
                    GeometryReader { geo in
                        Canvas { ctx, _ in
                            var mCtx = ctx
                            drawScatterChart(context: &mCtx, size: geo.size, pts: pts)
                        }
                    }
                    .frame(height: 210)

                    // Legend (colour encodes direction of error)
                    HStack(spacing: 14) {
                        scatterLegend(color: Color(hex: "2B00FF"), label: "On target")
                        scatterLegend(color: Color(hex: "FF4200"), label: "Took longer")
                        scatterLegend(color: Color(hex: "7C3AED"), label: "Finished early")
                    }

                    // Trend summary with dashed-line icon
                    HStack(alignment: .top, spacing: 8) {
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle().fill(Color.secondary.opacity(0.6)).frame(width: 5, height: 1.5)
                            }
                        }
                        .frame(width: 20).padding(.top, 5)
                        Text(scatterSummaryText)
                            .font(.system(size: 13)).foregroundColor(Color(hex: "8A8AAA"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func scatterLegend(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA"))
        }
    }

    // =========================================================================
    // MARK: - Regression Model Chart  (estimate → actual with confidence bands)
    // =========================================================================

    /// Fitted OLS regression model computed from stored category stats.
    private struct RegressionModel {
        let beta0: Double       // intercept
        let beta1: Double       // slope
        let xBar: Double        // mean estimate
        let Sxx: Double         // sum of squared deviations of x
        let s: Double           // residual standard deviation
        let n: Double           // number of observations
        let rSquared: Double    // coefficient of determination R²
    }

    private var regressionModel: RegressionModel? {
        guard let stats = vm.categoryStats[category.rawValue], stats.n >= 2 else { return nil }
        let n = stats.n
        let xBar = stats.sumX / n,  yBar = stats.sumY / n
        let Sxx  = stats.sumXX - stats.sumX * stats.sumX / n
        let Sxy  = stats.sumXY - stats.sumX * stats.sumY / n
        let Syy  = stats.sumYY - stats.sumY * stats.sumY / n
        guard Sxx > 1e-9 else { return nil }
        let beta1 = Sxy / Sxx
        let beta0 = yBar - beta1 * xBar
        let rss   = Syy - beta1 * Sxy
        let s2raw = rss / max(n - 2, 1)
        let s2    = s2raw.isFinite && s2raw > 0 ? s2raw : 1.0
        let rSq   = Syy > 1e-9 ? max(0.0, min(1.0, 1.0 - rss / Syy)) : 0.0
        return RegressionModel(beta0: beta0, beta1: beta1, xBar: xBar,
                               Sxx: Sxx, s: sqrt(s2), n: n, rSquared: rSq)
    }

    /// Hardcoded two-tailed t critical values (same table as AIEngine).
    private func chartTValue(df: Int, confidence: Int) -> Double {
        let table: [Int: [Int: Double]] = [
            1:  [80: 3.078, 85: 4.165, 90: 6.314,  95: 12.706],
            2:  [80: 1.886, 85: 2.282, 90: 2.920,  95: 4.303],
            3:  [80: 1.638, 85: 1.924, 90: 2.353,  95: 3.182],
            4:  [80: 1.533, 85: 1.778, 90: 2.132,  95: 2.776],
            5:  [80: 1.476, 85: 1.699, 90: 2.015,  95: 2.571],
            6:  [80: 1.440, 85: 1.650, 90: 1.943,  95: 2.447],
            7:  [80: 1.415, 85: 1.617, 90: 1.895,  95: 2.365],
            8:  [80: 1.397, 85: 1.592, 90: 1.860,  95: 2.306],
            9:  [80: 1.383, 85: 1.574, 90: 1.833,  95: 2.262],
            10: [80: 1.372, 85: 1.559, 90: 1.812,  95: 2.228],
            15: [80: 1.341, 85: 1.517, 90: 1.753,  95: 2.131],
            20: [80: 1.325, 85: 1.497, 90: 1.725,  95: 2.086],
            30: [80: 1.310, 85: 1.476, 90: 1.697,  95: 2.042],
        ]
        let keys     = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30]
        let closestDf = keys.last(where: { $0 <= max(df, 1) }) ?? 30
        return table[closestDf]?[confidence] ?? 1.282
    }

    /// Compute a "nice" axis step that produces ~targetSteps labels for a given range.
    private func niceStep(range: Double, targetSteps: Int) -> Double {
        guard range > 0, targetSteps > 0 else { return 1 }
        let raw       = range / Double(targetSteps)
        let magnitude = pow(10, floor(log10(raw)))
        let fraction  = raw / magnitude
        let nice: Double
        if      fraction < 1.5 { nice = 1 }
        else if fraction < 3.0 { nice = 2 }
        else if fraction < 7.0 { nice = 5 }
        else                   { nice = 10 }
        return nice * magnitude
    }

    private func drawRegressionChart(context: inout GraphicsContext,
                                     size: CGSize,
                                     model: RegressionModel) {
        let leftPad:   CGFloat = 52
        let rightPad:  CGFloat = 12
        let topPad:    CGFloat = 14
        let bottomPad: CGFloat = 28

        let chartW = size.width  - leftPad - rightPad
        let chartH = size.height - topPad  - bottomPad
        guard chartW > 0, chartH > 0 else { return }

        // ── Scatter data (estimate, actual) from current task list ────────────
        let pts: [(x: Double, y: Double)] = tasksChronological.compactMap { t in
            guard let actual = t.actualDurationMinutes else { return nil }
            return (Double(t.finalEstimateMinutes), Double(actual))
        }

        // ── Axis ranges ───────────────────────────────────────────────────────
        let allX = pts.map { $0.x };  let allY = pts.map { $0.y }
        let xMin = 0.0
        let xMax = max(ceil(((allX.max() ?? 60) * 1.2) / 10) * 10, 30.0)

        let df   = max(1, Int(model.n) - 2)
        let t95  = chartTValue(df: df, confidence: 95)
        let lev95atMax = 1.0 + 1.0/model.n + pow(xMax - model.xBar, 2) / model.Sxx
        let upperAtMax = model.beta0 + model.beta1 * xMax + t95 * model.s * sqrt(max(lev95atMax, 1))
        let yMin = 0.0
        let yMax = max(ceil(max((allY.max() ?? 60) * 1.15, upperAtMax * 1.05) / 10) * 10, 30.0)

        // ── Coordinate helpers ────────────────────────────────────────────────
        func sx(_ x: Double) -> CGFloat {
            leftPad + CGFloat(min(max(x, xMin), xMax) / (xMax - xMin == 0 ? 1 : xMax - xMin)) * chartW
        }
        func sy(_ y: Double) -> CGFloat {
            topPad + CGFloat(1.0 - min(max(y, yMin), yMax) / (yMax - yMin == 0 ? 1 : yMax - yMin)) * chartH
        }

        // ── 1. Y-axis grid + labels ────────────────────────────────────────────
        let yStep = niceStep(range: yMax, targetSteps: 4)
        var yTick = 0.0
        while yTick <= yMax + yStep * 0.01 {
            let sY = sy(yTick)
            var g = Path()
            g.move(to: CGPoint(x: leftPad, y: sY))
            g.addLine(to: CGPoint(x: leftPad + chartW, y: sY))
            context.stroke(g, with: .color(Color(white: 0.75, opacity: 0.5)),
                           style: StrokeStyle(lineWidth: 0.7))
            context.draw(
                Text("\(Int(yTick))")
                    .font(.system(size: 9)).foregroundColor(Color(white: 0.55)),
                at: CGPoint(x: leftPad - 5, y: sY), anchor: .trailing)
            yTick += yStep
        }

        // X-axis labels
        let xStep = niceStep(range: xMax, targetSteps: 4)
        var xTick = 0.0
        while xTick <= xMax + xStep * 0.01 {
            let sX = sx(xTick)
            context.draw(
                Text("\(Int(xTick))")
                    .font(.system(size: 9)).foregroundColor(Color(white: 0.55)),
                at: CGPoint(x: sX, y: topPad + chartH + 5), anchor: .top)
            xTick += xStep
        }

        // ── 2. Confidence bands (annular rings: outermost = darkest) ──────────
        //
        // Strategy: compute the curve bounds (high/low) for each confidence level
        // at numSteps x-values, then draw NON-OVERLAPPING rings so that alpha
        // values don't accumulate (outer stays darker than inner).
        //
        // Ring layout (filled annular strips, outer → inner):
        //   Ring 1 (darkest):   between 90 % and 95 % bounds
        //   Ring 2:             between 85 % and 90 %
        //   Ring 3:             between 80 % and 85 %
        //   Ring 4 (lightest):  inside 80 % (the entire ± band)

        let numSteps = 80
        let confs    = [95, 90, 85, 80]
        struct BandCurves { var highs: [CGPoint]; var lows: [CGPoint] }
        var bandMap: [Int: BandCurves] = [:]

        for conf in confs {
            let t = chartTValue(df: df, confidence: conf)
            var highs: [CGPoint] = []; var lows: [CGPoint] = []
            for i in 0...numSteps {
                let xData = xMin + Double(i) / Double(numSteps) * (xMax - xMin)
                let yHat  = model.beta0 + model.beta1 * xData
                let lev   = 1.0 + 1.0/model.n + pow(xData - model.xBar, 2) / model.Sxx
                let margin = t * model.s * sqrt(max(lev, 1.0))
                highs.append(CGPoint(x: sx(xData), y: sy(yHat + margin)))
                lows.append( CGPoint(x: sx(xData), y: sy(max(yHat - margin, yMin))))
            }
            bandMap[conf] = BandCurves(highs: highs, lows: lows)
        }

        // (outer confidence level, inner confidence level or nil, fill alpha)
        let rings: [(outer: Int, inner: Int?, alpha: CGFloat)] = [
            (95, 90, 0.14),  // 90 %–95 % strip — darkest
            (90, 85, 0.13),
            (85, 80, 0.12),
            (80, nil, 0.09), // within 80 %   — lightest
        ]

        for ring in rings {
            guard let outer = bandMap[ring.outer] else { continue }
            var path = Path()

            if let ic = ring.inner, let inner = bandMap[ic] {
                // Upper strip: forward along outer-high, back along inner-high
                if let f = outer.highs.first { path.move(to: f) }
                outer.highs.dropFirst().forEach { path.addLine(to: $0) }
                inner.highs.reversed().forEach  { path.addLine(to: $0) }
                path.closeSubpath()

                // Lower strip: forward along inner-low, back along outer-low
                if let f = inner.lows.first { path.move(to: f) }
                inner.lows.dropFirst().forEach { path.addLine(to: $0) }
                outer.lows.reversed().forEach  { path.addLine(to: $0) }
                path.closeSubpath()
            } else {
                // Innermost region (within 80 %): high curve → low curve back
                if let f = outer.highs.first { path.move(to: f) }
                outer.highs.dropFirst().forEach { path.addLine(to: $0) }
                outer.lows.reversed().forEach   { path.addLine(to: $0) }
                path.closeSubpath()
            }

            context.fill(path, with: .color(Color.tfBlue.opacity(ring.alpha)))
        }

        // ── 3. Perfect-estimate reference  y = x  (dashed gray) ──────────────
        let perfEnd = min(xMax, yMax)
        var perf = Path()
        perf.move(to: CGPoint(x: sx(xMin), y: sy(xMin)))
        perf.addLine(to: CGPoint(x: sx(perfEnd), y: sy(perfEnd)))
        context.stroke(perf, with: .color(Color(white: 0.50, opacity: 0.85)),
                       style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))

        // ── 4. Regression line (solid blue) ──────────────────────────────────
        var regLine = Path()
        regLine.move(to: CGPoint(x: sx(xMin), y: sy(model.beta0 + model.beta1 * xMin)))
        regLine.addLine(to: CGPoint(x: sx(xMax), y: sy(model.beta0 + model.beta1 * xMax)))
        context.stroke(regLine, with: .color(Color.tfBlue),
                       style: StrokeStyle(lineWidth: 2))

        // ── 5. Scatter data points ────────────────────────────────────────────
        let dotR: CGFloat = 5.5
        for (xData, yData) in pts {
            let center   = CGPoint(x: sx(xData), y: sy(yData))
            let signedErr = xData > 0 ? (yData - xData) / xData * 100 : 0
            let rect      = CGRect(x: center.x - dotR, y: center.y - dotR,
                                   width: dotR * 2, height: dotR * 2)
            let dotPath   = Path(ellipseIn: rect)
            context.fill(dotPath, with: .color(dotColor(for: signedErr)))
            context.stroke(dotPath, with: .color(.white), style: StrokeStyle(lineWidth: 1.5))
        }

        // ── 6. Confidence-level annotations at the right edge ─────────────────
        if let c95 = bandMap[95], let c80 = bandMap[80],
           let top95 = c95.highs.last, let top80 = c80.highs.last,
           top95.y < top80.y - 16 {
            let rx = sx(xMax * 0.88)
            context.draw(Text("wider").font(.system(size: 8))
                            .foregroundColor(Color.tfBlue.opacity(0.65)),
                         at: CGPoint(x: rx, y: top95.y), anchor: .bottom)
            context.draw(Text("likely").font(.system(size: 8))
                            .foregroundColor(Color.tfBlue.opacity(0.50)),
                         at: CGPoint(x: rx, y: top80.y), anchor: .top)
        }
    }

    private var regressionChartCard: some View {
        SectionCard(title: "Does your guess match reality?",
                    icon: "function",
                    iconColor: category.color) {
            VStack(alignment: .leading, spacing: 12) {
                if let model = regressionModel {
                    // Chart canvas
                    GeometryReader { geo in
                        Canvas { ctx, _ in
                            var mCtx = ctx
                            drawRegressionChart(context: &mCtx, size: geo.size, model: model)
                        }
                    }
                    .frame(height: 240)

                    // Task count summary
                    Text("Based on \(Int(model.n)) tasks")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8AAA"))

                    // Legend
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 16) {
                            HStack(spacing: 5) {
                                Rectangle().fill(Color.tfBlue).frame(width: 16, height: 2)
                                Text("your trend").font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA"))
                            }
                            HStack(spacing: 5) {
                                HStack(spacing: 2) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color(white: 0.50, opacity: 0.85))
                                            .frame(width: 5, height: 1.5)
                                    }
                                }
                                Text("perfect estimate").font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA"))
                            }
                        }
                        HStack(spacing: 5) {
                            ZStack {
                                // Outer band (darker)
                                Rectangle().fill(Color.tfBlue.opacity(0.14)).frame(width: 22, height: 10)
                                // Inner band (lighter on top)
                                Rectangle().fill(Color.tfBlue.opacity(0.09)).frame(width: 12, height: 10)
                            }
                            .cornerRadius(2)
                            Text("likely range (shaded area)")
                                .font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA"))
                        }
                    }
                } else {
                    Text(tasks.count < 2
                         ? "Complete at least 2 \(category.rawValue.lowercased()) tasks to unlock this chart."
                         : "Your estimates are very similar — not enough variation to show a pattern yet.")
                        .font(.system(size: 14)).foregroundColor(Color(hex: "8A8AAA"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // =========================================================================
    // MARK: - Trend card
    // =========================================================================

    private var trendCard: some View {
        let t = trend
        return SectionCard(title: "Trend", icon: t.icon, iconColor: t.color) {
            Text(t.text)
                .font(.system(size: 14)).foregroundColor(Color(hex: "8A8AAA"))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }

    // =========================================================================
    // MARK: - Notable tasks
    // =========================================================================

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
                .font(.system(size: 11, weight: .semibold)).foregroundColor(badgeColor)
                .textCase(.uppercase)
            Text(task.title)
                .font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "1A1A2E")).lineLimit(1)
            HStack(spacing: 16) {
                miniStat("Estimated", "\(task.finalEstimateMinutes) min")
                miniStat("Actual", "\(task.actualDurationMinutes ?? 0) min")
                if let diff = task.estimationDifferenceMinutes {
                    miniStat("Diff",
                             diff >= 0 ? "+\(diff) min" : "\(diff) min",
                             color: abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue))
                }
            }
        }
    }

    // =========================================================================
    // MARK: - All tasks list
    // =========================================================================

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
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "1A1A2E")).lineLimit(1)
                Spacer()
                EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
            }
            HStack(spacing: 16) {
                miniStat("Estimated", "\(task.finalEstimateMinutes) min")
                miniStat("Actual", "\(task.actualDurationMinutes ?? 0) min")
                if let diff = task.estimationDifferenceMinutes {
                    miniStat("Diff",
                             diff >= 0 ? "+\(diff) min" : "\(diff) min",
                             color: abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue))
                }
                if task.finalEstimateMinutes > 0, let a = task.actualDurationMinutes {
                    let pct = Int(Double(a - task.finalEstimateMinutes) / Double(task.finalEstimateMinutes) * 100)
                    miniStat("% off",
                             pct >= 0 ? "+\(pct)%" : "\(pct)%",
                             color: abs(pct) <= 5 ? Color(hex: "059669") : (pct > 0 ? .tfOrange : .tfBlue))
                }
            }
            if let date = task.completedAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA"))
            }
        }
    }

    private func miniStat(_ label: String, _ value: String, color: Color = .tfDark) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "8A8AAA"))
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(color)
        }
    }
}
