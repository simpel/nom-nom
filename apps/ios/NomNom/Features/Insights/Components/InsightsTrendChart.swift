import SwiftUI
import Charts

struct InsightsTrendChart: View {
    let trendData: [(date: Date, averageScore: Double)]
    let domain: ClosedRange<Double>
    let valueFormat: String
    
    init(trendData: [(date: Date, averageScore: Double)], domain: ClosedRange<Double> = 0...1.0, valueFormat: String = "%.2f") {
        self.trendData = trendData
        self.domain = domain
        self.valueFormat = valueFormat
    }
    
    @State private var selectedDate: Date?
    
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
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.averageScore)
                    )
                    .foregroundStyle(DS.Color.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.averageScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [DS.Color.accentSoft.opacity(0.3), DS.Color.accentSoft.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                if let selectedDate {
                    RuleMark(
                        x: .value("Selected", selectedDate)
                    )
                    .foregroundStyle(DS.Color.lineStrong)
                    .annotation(position: .top) {
                        if let score = score(for: selectedDate) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedDate, format: .dateTime.month().day())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: valueFormat, score))
                                    .font(.headline)
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            .padding(8)
                            .background(DS.Color.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 3)
                        }
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
                                        // find closest date
                                        selectedDate = closestDate(to: date)
                                    }
                                }
                                .onEnded { _ in
                                    selectedDate = nil
                                }
                        )
                }
            }
            .frame(height: 150)
        }
    }
    
    private func closestDate(to target: Date) -> Date? {
        trendData.min(by: { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) })?.date
    }
    
    private func score(for date: Date) -> Double? {
        trendData.first(where: { $0.date == date })?.averageScore
    }
}
