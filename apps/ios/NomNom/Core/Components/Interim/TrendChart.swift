// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI
import Charts

/// The one trend chart (Swift Charts) in a `sm` Card: an optional `total` line in
/// `primary` plus any number of member series in `chart-series` colours by stable
/// index, over `line` gridlines. Values are 0–1 and read ×100.
///
/// - Single-series mode (no `series`): the total line gets a `primary` area fill.
/// - Drag across the chart to scrub; the nearest date gets a rule and a tooltip
///   (Card + `shadow-lg`) listing every series' value on that day.
/// - `visibleDays` makes the x axis scroll, starting at the latest data.
/// - `framed: false` drops the Card so the chart can run edge to edge on a screen.
///
/// ```swift
/// TrendChart(total: points)
/// TrendChart(total: partyTrend, series: members, visibleDays: 14)
/// ```
struct TrendChart: View {
    var total: [TrendPoint]
    var totalName: String
    var series: [TrendSeries]
    var visibleDays: Int?
    var emptyMessage: String
    var framed: Bool

    @State private var rawSelection: Date?
    @State private var scrollPosition: Date = .now

    init(
        total: [TrendPoint] = [],
        totalName: String = "Average",
        series: [TrendSeries] = [],
        visibleDays: Int? = nil,
        emptyMessage: String = "Not enough data to show a trend yet",
        framed: Bool = true
    ) {
        self.total = total.sorted { $0.date < $1.date }
        self.totalName = totalName
        self.series = series
        self.visibleDays = visibleDays
        self.emptyMessage = emptyMessage
        self.framed = framed
    }

    private static let height = DS.Spacing.s48
    private static let yDomain: ClosedRange<Double> = 0...1.05
    private static let gridValues: [Double] = [0.25, 0.5, 0.75, 1.0]
    private static let day: TimeInterval = 24 * 60 * 60
    // README "Scales": `border-hairline` and `border-thick` are "the only two widths the
    // system draws". The total is a solid `border-thick` line; members are dashed at
    // `border-hairline` so the total leads (DS-GAPS.md, "core").
    private static let totalStroke = StrokeStyle(lineWidth: DS.BorderWidth.thick, lineCap: .round)
    private static let memberStroke = StrokeStyle(lineWidth: DS.BorderWidth.hairline, dash: [DS.Spacing.s1, DS.Spacing.s1])

    private var isAreaMode: Bool { series.isEmpty }
    private var allDates: [Date] { total.map(\.date) + series.flatMap { $0.points.map(\.date) } }
    private var isEmpty: Bool { allDates.isEmpty }

    private var selectedDate: Date? {
        guard let rawSelection else { return nil }
        return allDates.min { abs($0.timeIntervalSince(rawSelection)) < abs($1.timeIntervalSince(rawSelection)) }
    }

    var body: some View {
        if framed {
            Card(size: .sm) { content }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if isEmpty {
            Text(emptyMessage)
                .textStyle(.sansMd, tone: .secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: Self.height)
        } else {
            scrollable(chart)
                .frame(height: Self.height)
                .sensoryFeedback(.selection, trigger: selectedDate)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series) { line in
                ForEach(Array(line.points.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.value),
                        series: .value("Series", line.name)
                    )
                    .foregroundStyle(line.color)
                    .lineStyle(Self.memberStroke)
                    .interpolationMethod(.monotone)

                    PointMark(x: .value("Date", point.date), y: .value("Score", point.value))
                        .foregroundStyle(line.color)
                        .symbolSize(DS.Spacing.s5)
                }
            }

            ForEach(Array(total.enumerated()), id: \.offset) { _, point in
                if isAreaMode {
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.value),
                        series: .value("Series", totalName)
                    )
                    .foregroundStyle(areaGradient)
                    .interpolationMethod(.monotone)
                }
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.value),
                    series: .value("Series", totalName)
                )
                .foregroundStyle(DS.Color.primary)
                .lineStyle(Self.totalStroke)
                .interpolationMethod(.monotone)
            }

            if let selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(DS.Color.lineStrong)
                    .lineStyle(Self.memberStroke)
                    .annotation(
                        position: .top,
                        spacing: DS.Spacing.s1,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        TrendChartTooltip(date: selectedDate, entries: tooltipEntries(at: selectedDate))
                    }

                if let value = totalValue(at: selectedDate) {
                    PointMark(x: .value("Date", selectedDate), y: .value("Score", value))
                        .foregroundStyle(DS.Color.primary)
                        .symbolSize(DS.Spacing.s16)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: Self.gridValues) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: DS.Spacing.s0_5 / 2))
                    .foregroundStyle(DS.Color.line)
            }
        }
        .chartYScale(domain: Self.yDomain)
        .chartXSelection(value: $rawSelection)
    }

    @ViewBuilder
    private func scrollable<C: View>(_ content: C) -> some View {
        if let visibleDays, let last = allDates.max() {
            content
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: Double(visibleDays) * Self.day)
                .chartScrollPosition(x: $scrollPosition)
                .onAppear {
                    // End one day past the latest point so its dot has room.
                    scrollPosition = last.addingTimeInterval(Self.day * Double(1 - visibleDays))
                }
        } else {
            content
        }
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.primary.opacity(DS.Opacity.o30),
                DS.Color.primary.opacity(DS.Opacity.o10),
                DS.Color.primary.opacity(DS.Opacity.o0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func totalValue(at date: Date) -> Double? {
        total.first { $0.date == date }?.value
    }

    private func tooltipEntries(at date: Date) -> [TrendTooltipEntry] {
        var entries: [TrendTooltipEntry] = []
        if !total.isEmpty {
            entries.append(TrendTooltipEntry(id: "total", name: totalName, color: DS.Color.primary, value: totalValue(at: date)))
        }
        entries += series.map {
            TrendTooltipEntry(id: $0.id, name: $0.name, color: $0.color, value: $0.value(near: date))
        }
        return entries
    }
}

private struct TrendChartGallery: View {
    private static func points(_ values: [Double]) -> [TrendPoint] {
        values.enumerated().map { index, value in
            TrendPoint(date: Date.now.addingTimeInterval(Double(index - values.count) * 86_400), value: value)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                TrendChart(total: Self.points([0.4, 0.55, 0.5, 0.7, 0.8, 0.75]))
                TrendChart(
                    total: Self.points([0.6, 0.7, 0.65, 0.8, 0.9]),
                    series: [
                        TrendSeries(id: 0, name: "Anna", colorIndex: 0, points: Self.points([0.8, 0.6, 0.8, 1.0, 0.8])),
                        TrendSeries(id: 1, name: "Joel", colorIndex: 1, points: Self.points([0.4, 0.8, 0.6, 0.6, 1.0])),
                    ]
                )
                TrendChart()
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { TrendChartGallery() }
#Preview("Dark") { TrendChartGallery().preferredColorScheme(.dark) }
