import SwiftUI
import Charts

/// A party's average-rating trend, broken down into one line per rater (member or
/// household eater) plus a bold "Total" line for the party average. Dragging shows
/// a tooltip that highlights the total and lists each visible rater's score for
/// that meal.
struct PartyTasteTrendChart: View {
    let totalTrend: [(date: Date, averageScore: Double)]
    let memberSeries: [MemberTrendSeries]
    let domain: ClosedRange<Double>
    let valueFormat: String

    init(
        totalTrend: [(date: Date, averageScore: Double)],
        memberSeries: [MemberTrendSeries],
        domain: ClosedRange<Double> = 0...1.0,
        valueFormat: String = "%.2f"
    ) {
        self.totalTrend = totalTrend
        self.memberSeries = memberSeries
        self.domain = domain
        self.valueFormat = valueFormat
    }

    @State private var selectedDate: Date?

    /// Categorical hues run out past this many raters; the rest still count
    /// toward Total but aren't drawn as their own line, to keep the legend and
    /// chart legible.
    private static let maxIndividualSeries = DS.Color.Chart.series.count

    private var visibleSeries: [MemberTrendSeries] {
        Array(memberSeries.prefix(Self.maxIndividualSeries))
    }

    private var overflowCount: Int {
        max(0, memberSeries.count - Self.maxIndividualSeries)
    }

    private func color(for index: Int) -> Color {
        DS.Color.Chart.series[index % DS.Color.Chart.series.count]
    }

    var body: some View {
        if totalTrend.isEmpty {
            VStack {
                Text("Not enough data to show trend")
                    .foregroundStyle(.secondary)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(DS.Color.panel)
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                chart
                legend
                if overflowCount > 0 {
                    Text("+\(overflowCount) more contributing to Total")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(Array(visibleSeries.enumerated()), id: \.element.id) { index, series in
                ForEach(series.points, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score),
                        series: .value("Rater", series.name)
                    )
                    .foregroundStyle(color(for: index))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol {
                        Circle()
                            .fill(color(for: index))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            ForEach(totalTrend, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Score", item.averageScore),
                    series: .value("Rater", "__total__")
                )
                .foregroundStyle(DS.Color.accent)
                .lineStyle(StrokeStyle(lineWidth: 3.5))

                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Score", item.averageScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [DS.Color.accentSoft.opacity(0.35), DS.Color.accentSoft.opacity(0.0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            if let selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(DS.Color.lineStrong)
                    .annotation(position: .top, alignment: .leading) {
                        tooltip(for: selectedDate)
                    }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: domain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = closestDate(to: date)
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                            }
                    )
            }
        }
        .frame(height: 180)
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                legendChip(color: DS.Color.accent, label: "Total")
                ForEach(Array(visibleSeries.enumerated()), id: \.element.id) { index, series in
                    legendChip(color: color(for: index), label: series.name)
                }
            }
        }
    }

    private func legendChip(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    @ViewBuilder
    private func tooltip(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(date, format: .dateTime.month().day())
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Circle().fill(DS.Color.accent).frame(width: 8, height: 8)
                Text("Total")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer(minLength: 16)
                Text(totalScore(at: date).map { String(format: valueFormat, $0) } ?? "—")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Color.accent)
            }

            ForEach(Array(visibleSeries.enumerated()), id: \.element.id) { index, series in
                if let score = series.points.first(where: { $0.date == date })?.score {
                    HStack(spacing: 6) {
                        Circle().fill(color(for: index)).frame(width: 8, height: 8)
                        Text(series.name)
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        Spacer(minLength: 16)
                        Text(String(format: valueFormat, score))
                            .font(.caption)
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: 170, alignment: .leading)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 3)
    }

    private func closestDate(to target: Date) -> Date? {
        totalTrend.min(by: { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) })?.date
    }

    private func totalScore(at date: Date) -> Double? {
        totalTrend.first(where: { $0.date == date })?.averageScore
    }
}
