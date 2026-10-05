import SwiftUI

/// One slice of a SegmentedBar: a label, a value (its width is the value's share of the
/// sum) and what paints it. Only taste distributions use the reaction ramp; everything
/// else takes `chart-series*` by a stable index (`.chart(n)`), never cycled.
struct SegmentedBarSegment: Identifiable {
    var id: String { label }
    let label: String
    let value: Double
    var ink: BarSegment.Ink?

    init(label: String, value: Double, ink: BarSegment.Ink? = nil) {
        self.label = label
        self.value = value
        self.ink = ink
    }

    /// A taste tier: the reaction's name and `reaction-<step>-fill`.
    init(reaction: Reaction, value: Double) {
        self.init(label: reaction.name, value: value, ink: .reaction(reaction))
    }

    var bar: BarSegment { BarSegment(value: value, ink: ink, label: label) }
    var color: Color { bar.color }
}

extension Array where Element == SegmentedBarSegment {
    /// Every reaction tier in scale order, Can't eat → Amazing, zeros included
    /// (README: "A tier at zero is never dimmed"; "Never sort by size").
    static func reactions(_ counts: [Reaction: Int]) -> [SegmentedBarSegment] {
        Reaction.allCases.sorted().map { SegmentedBarSegment(reaction: $0, value: Double(counts[$0] ?? 0)) }
    }
}

/// SegmentedBar's key: inline swatches, a RatingList of rows, or none.
enum SegmentedBarLegend: Equatable {
    /// No key: a bar inside a row or card that a nearby label already explains.
    case none
    /// Swatch + label keys wrapped under the bar (up to about six short tiers).
    case inline
    /// The breakdown is a RatingList: one row per tier with its figure read down a column.
    case rows
}

/// How the legend figures read.
enum SegmentedBarFormat: Equatable {
    case count, percent
}

/// SegmentedBar thicknesses.
///
/// README: "`sm` (`spacing-1.5`) · `md` (`spacing-2.5`) · `lg` (`spacing-4`)". Bar
/// README has five thicknesses and stops at `xl` 12 (`spacing-3`); SegmentedBar is
/// built from Bar, so `lg` is Bar `xl` (see DS-GAPS.md).
enum SegmentedBarSize: Equatable {
    case sm, md, lg

    var bar: BarSize {
        switch self {
        case .sm: return .sm
        case .md: return .lg
        case .lg: return .xl
        }
    }
}
