import SwiftUI
import Charts

/// A party's average-rating trend compared with member ratings.
/// - Tooltip floats above the white card so it's never clipped.
/// - Tooltip persists after drag; dismiss via X button or tap anywhere on the chart.
/// - Party average: solid area + line, permanent dot on every meal day.
/// - Members: thin 1 px dashed lines with dots at each actual rating.
/// - Lines stop at the last known meal day.
struct PartyTasteTrendChart: View {
    let totalTrend: [(date: Date, averageScore: Double)]
    let memberSeries: [MemberTrendSeries]
    let domain: ClosedRange<Double>
    let valueFormat: String

    init(
        totalTrend: [(date: Date, averageScore: Double)],
        memberSeries: [MemberTrendSeries],
        domain: ClosedRange<Double> = 0...105,
        valueFormat: String = "%.0f"
    ) {
        self.totalTrend = totalTrend
        self.memberSeries = memberSeries
        self.domain = domain
        self.valueFormat = valueFormat
    }

    @State private var scrollPosition: Date = Date()
    @State private var selectedDate: Date?
    @State private var tooltipLeading: Bool = true

    private var primaryColor: Color { DS.Color.Chart.total }

    // MARK: - Derived data

    private var lastMealDate: Date { totalTrend.map(\.date).max() ?? Date() }

    private var smoothedTotal: [(date: Date, score: Double)] {
        smooth(points: totalTrend.map { (date: $0.date, score: $0.averageScore) })
    }

    private func smoothedMember(_ series: MemberTrendSeries) -> [(date: Date, score: Double)] {
        smooth(points: series.points)
    }

    private func smooth(
        points: [(date: Date, score: Double)],
        windowSize: Int = 4
    ) -> [(date: Date, score: Double)] {
        guard points.count > 2 else { return points }
        return (0..<points.count).map { i in
            let start = max(0, i - windowSize / 2)
            let end   = min(points.count - 1, i + windowSize / 2)
            let slice = points[start...end]
            let avg   = slice.reduce(0.0) { $0 + $1.score } / Double(slice.count)
            return (date: points[i].date, score: avg)
        }
    }

    private var initialScrollPosition: Date {
        // End one day past the last meal so the final dot has breathing room on the right.
        let trailingEdge = Calendar.current.date(byAdding: .day, value: 1, to: lastMealDate) ?? lastMealDate
        return Calendar.current.date(byAdding: .day, value: -14, to: trailingEdge) ?? trailingEdge
    }

    // MARK: - Body

    var body: some View {
        if totalTrend.isEmpty {
            SectionCard(title: nil, innerPadding: 16) {
                Text("Not enough data to show trend")
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                // Tooltip lives ABOVE the card — never clipped, always fully visible
                if let sel = selectedDate {
                    tooltipView(for: sel)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // White card — chart only
                chartView
                    .onAppear { scrollPosition = initialScrollPosition }
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .fill(DS.Color.panel)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                    }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedDate != nil)
        }
    }

    // MARK: - Tooltip view (above the card)

    @ViewBuilder
    private func tooltipView(for date: Date) -> some View {
        let entries: [TooltipEntry] = memberSeries.enumerated().map { index, series in
            TooltipEntry(
                label: series.name,
                color: DS.Color.Chart.series[index % DS.Color.Chart.series.count],
                score: memberScore(series: series, at: date)
            )
        }
        HStack(alignment: .top) {
            if !tooltipLeading { Spacer(minLength: 0) }
            PartyTrendTooltipCard(
                date: date,
                primaryLabel: "Average",
                primaryScore: totalScore(at: date),
                primaryColor: primaryColor,
                valueFormat: valueFormat,
                memberEntries: entries,
                onDismiss: { withAnimation { selectedDate = nil } }
            )
            if tooltipLeading { Spacer(minLength: 0) }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            memberLinesAndDots
            totalAreaLine
            totalPermanentDots
            selectionMarks
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: TimeInterval(14 * 24 * 60 * 60))
        .chartScrollPosition(x: $scrollPosition)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(DS.Color.Chart.gridLine.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [25.0, 50.0, 75.0, 100.0]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(DS.Color.Chart.gridLine.opacity(0.35))
            }
        }
        .chartYScale(domain: domain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    // Tap: dismiss if tooltip open, or select date
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded {
                                withAnimation { selectedDate = nil }
                            }
                    )
                    // Drag: scrub to select date, tooltip stays after release
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                let plotFrame = geometry[proxy.plotAreaFrame]
                                let x = value.location.x - plotFrame.origin.x
                                guard x >= 0, x <= plotFrame.width else { return }
                                if let date: Date = proxy.value(atX: x) {
                                    let snapped = closestMealDate(to: date)
                                    if snapped != selectedDate {
                                        selectedDate = snapped
                                    }
                                    tooltipLeading = x < plotFrame.width * 0.5
                                }
                            }
                        // No .onEnded clear — tooltip persists after release
                    )
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    // MARK: - Chart marks

    @ChartContentBuilder
    private var memberLinesAndDots: some ChartContent {
        ForEach(Array(memberSeries.enumerated()), id: \.element.id) { index, series in
            let color = DS.Color.Chart.series[index % DS.Color.Chart.series.count]
            ForEach(smoothedMember(series), id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Score", item.score),
                    series: .value("Member", series.name)
                )
                .foregroundStyle(color.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .interpolationMethod(.monotone)
            }
            ForEach(series.points, id: \.date) { item in
                PointMark(x: .value("Date", item.date), y: .value("Score", item.score))
                    .foregroundStyle(color.opacity(0.8))
                    .symbolSize(18)
            }
        }
    }

    @ChartContentBuilder
    private var totalAreaLine: some ChartContent {
        ForEach(smoothedTotal, id: \.date) { item in
            AreaMark(
                x: .value("Date", item.date),
                y: .value("Score", item.score),
                series: .value("Series", "Party Average")
            )
            .foregroundStyle(LinearGradient(
                stops: [
                    .init(color: primaryColor.opacity(0.32), location: 0.0),
                    .init(color: primaryColor.opacity(0.10), location: 0.55),
                    .init(color: primaryColor.opacity(0.0),  location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            ))
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", item.date),
                y: .value("Score", item.score),
                series: .value("Series", "Party Average")
            )
            .foregroundStyle(primaryColor)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.monotone)
        }
    }

    @ChartContentBuilder
    private var totalPermanentDots: some ChartContent {
        ForEach(totalTrend, id: \.date) { item in
            PointMark(x: .value("Date", item.date), y: .value("Score", item.averageScore))
                .foregroundStyle(primaryColor)
                .symbol {
                    Circle().fill(primaryColor).frame(width: 6, height: 6)
                        .overlay(Circle().stroke(DS.Color.panel, lineWidth: 1.5))
                }
        }
    }

    @ChartContentBuilder
    private var selectionMarks: some ChartContent {
        if let sel = selectedDate {
            RuleMark(x: .value("Selected", sel))
                .foregroundStyle(DS.Color.line.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

            if let total = totalScore(at: sel) {
                PointMark(x: .value("Date", sel), y: .value("Score", total))
                    .foregroundStyle(primaryColor)
                    .symbol {
                        Circle().fill(primaryColor).frame(width: 9, height: 9)
                            .overlay(Circle().stroke(DS.Color.panel, lineWidth: 1.5))
                    }
            }

            ForEach(Array(memberSeries.enumerated()), id: \.element.id) { index, series in
                let color = DS.Color.Chart.series[index % DS.Color.Chart.series.count]
                if let s = memberScore(series: series, at: sel) {
                    PointMark(x: .value("Date", sel), y: .value("Score", s))
                        .foregroundStyle(color)
                        .symbol {
                            Circle().fill(color).frame(width: 7, height: 7)
                                .overlay(Circle().stroke(DS.Color.panel, lineWidth: 1))
                        }
                }
            }
        }
    }

    // MARK: - Helpers

    private func closestMealDate(to target: Date) -> Date? {
        totalTrend.min(by: {
            abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target))
        })?.date
    }

    private func totalScore(at date: Date) -> Double? {
        totalTrend.first(where: { $0.date == date })?.averageScore
    }

    private func memberScore(series: MemberTrendSeries, at date: Date) -> Double? {
        series.points
            .filter { abs($0.date.timeIntervalSince(date)) < 43_200 }
            .min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })?
            .score
    }
}
