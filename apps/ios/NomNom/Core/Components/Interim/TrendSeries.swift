// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// One dated value on a TrendChart, normalised 0–1 (shown ×100).
struct TrendPoint: Hashable {
    let date: Date
    let value: Double
}

/// One line on a TrendChart: a party member, an eater, or any named series.
/// `colorIndex` is the series' stable index (e.g. its position in the party's
/// member order) and picks `DS.Color.chartSeries[colorIndex]`.
struct TrendSeries: Identifiable {
    let id: AnyHashable
    let name: String
    let colorIndex: Int
    let points: [TrendPoint]

    init(id: AnyHashable, name: String, colorIndex: Int, points: [TrendPoint]) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.points = points.sorted { $0.date < $1.date }
    }

    /// The series colour. The palette has seven steps; an eighth member repeats
    /// from the start (the DS has no rule past seven yet; see DS-GAPS.md).
    var color: Color {
        let palette = DS.Color.chartSeries
        return palette[colorIndex % palette.count]
    }

    /// The point nearest `date` within half a day, if any.
    func value(near date: Date) -> Double? {
        points
            .filter { abs($0.date.timeIntervalSince(date)) < TrendSeries.matchWindow }
            .min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?
            .value
    }

    /// Points within this window of a scrubbed date count as "on" that date.
    static let matchWindow: TimeInterval = 12 * 60 * 60
}

/// A row in the TrendChart tooltip.
struct TrendTooltipEntry: Identifiable {
    let id: AnyHashable
    let name: String
    let color: Color
    let value: Double?
}
