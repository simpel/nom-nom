import SwiftUI
import Charts

struct InsightsTrendChart: View {
    let trendData: [(date: Date, averageScore: Double)]
    let domain: ClosedRange<Double>
    let valueFormat: String
    
    init(trendData: [(date: Date, averageScore: Double)], domain: ClosedRange<Double> = 0...100, valueFormat: String = "%.0f") {
        self.trendData = trendData
        self.domain = domain
        self.valueFormat = valueFormat
    }
    
    @State private var selectedDate: Date?
    @State private var isSelectedDateOnRightSide: Bool = false
    
    var body: some View {
        if trendData.isEmpty {
            VStack {
                Text("Not enough data to show trend")
                    .foregroundStyle(.secondary)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(DS.Color.panel)
        } else {
            Chart {
                ForEach(trendData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.averageScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: DS.Color.accent.opacity(0.35), location: 0.0),
                                .init(color: DS.Color.accent.opacity(0.12), location: 0.55),
                                .init(color: DS.Color.accent.opacity(0.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.averageScore)
                    )
                    .foregroundStyle(DS.Color.Chart.total)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.monotone)
                }
                
                if let selectedDate {
                    RuleMark(x: .value("Selected", selectedDate))
                        .foregroundStyle(DS.Color.line.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .annotation(
                            position: .top,
                            alignment: isSelectedDateOnRightSide ? .trailing : .leading
                        ) {
                            PartyTrendTooltipCard(
                                date: selectedDate,
                                primaryLabel: "Health",
                                primaryScore: score(for: selectedDate),
                                primaryColor: DS.Color.Chart.total,
                                valueFormat: valueFormat
                            )
                        }

                    if let score = score(for: selectedDate) {
                        PointMark(
                            x: .value("Date", selectedDate),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(DS.Color.Chart.total)
                        .symbol {
                            Circle()
                                .fill(DS.Color.Chart.total)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(DS.Color.panel, lineWidth: 1.5))
                        }
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [25.0, 50.0, 75.0, 100.0]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(DS.Color.Chart.gridLine.opacity(0.35))
                }
            }
            .chartYScale(domain: domain)
            .clipped()
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let plotFrame = geometry[proxy.plotAreaFrame]
                                    let x = value.location.x - plotFrame.origin.x
                                    if let date: Date = proxy.value(atX: x) {
                                        let closest = closestDate(to: date)
                                        selectedDate = closest
                                        if let closest, let posX = proxy.position(forX: closest) {
                                            isSelectedDateOnRightSide = posX > (plotFrame.width * 0.5)
                                        } else {
                                            isSelectedDateOnRightSide = x > (plotFrame.width * 0.5)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedDate = nil
                                }
                        )
                }
            }
            .frame(height: 190)
        }
    }
    
    private func closestDate(to target: Date) -> Date? {
        trendData.min(by: { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) })?.date
    }
    
    private func score(for date: Date) -> Double? {
        trendData.first(where: { $0.date == date })?.averageScore
    }
}
