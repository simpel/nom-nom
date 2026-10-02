// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// One share of a SegmentedBar.
struct SegmentedBarSegment: Identifiable {
    var id: String { label }
    /// Any non-negative weight; widths are value / total.
    let value: Double
    /// A reaction fill, chart series or role colour token.
    let color: Color
    let label: String
    /// The legend value ("2 · 50%", "24 g"); defaults to the percentage.
    var valueText: String?
    /// A quieter second figure after the value ("96 kcal").
    var detail: String?
}

/// A distribution as one Bar split into coloured shares (1pt `panel` seams, Bar
/// `md` thick), with optional legend rows: a `s2` dot, the label (`sans-sm`) and the
/// value (`sans-sm` tabular). Used for reaction tiers, macros and health tiers.
///
/// ```swift
/// SegmentedBar([
///     SegmentedBarSegment(value: 3, color: Reaction.amazing.fill, label: "Amazing"),
///     SegmentedBarSegment(value: 1, color: Reaction.good.fill, label: "Good"),
/// ])
/// ```
struct SegmentedBar: View {
    let segments: [SegmentedBarSegment]
    var size: BarSize
    var showsLegend: Bool
    /// Accessible name for the bar, e.g. "Rating distribution".
    var label: String?

    init(
        _ segments: [SegmentedBarSegment],
        size: BarSize = .md,
        showsLegend: Bool = true,
        label: String? = nil
    ) {
        self.segments = segments
        self.size = size
        self.showsLegend = showsLegend
        self.label = label
    }

    private var visible: [SegmentedBarSegment] { segments.filter { $0.value > 0 } }
    private var total: Double { visible.reduce(0) { $0 + $1.value } }

    private func percent(_ segment: SegmentedBarSegment) -> Int {
        guard total > 0 else { return 0 }
        return Int((segment.value / total * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            Bar(
                segments: visible.map { BarSegment(value: $0.value, ink: .color($0.color), label: $0.label) },
                size: size,
                label: label ?? "Distribution"
            )
            if showsLegend {
                VStack(spacing: DS.Spacing.s2) {
                    ForEach(visible) { legendRow($0) }
                }
            }
        }
    }

    private func legendRow(_ segment: SegmentedBarSegment) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Circle()
                .fill(segment.color)
                .frame(width: DS.Spacing.s2, height: DS.Spacing.s2)
                .accessibilityHidden(true)
            Text(segment.label).textStyle(.sansSm)
            Spacer(minLength: DS.Spacing.s2)
            Text(segment.valueText ?? "\(percent(segment))%")
                .textStyle(.sansSm, tone: .secondary, numeric: true)
            if let detail = segment.detail {
                Text(detail).textStyle(.sansSm, tone: .tertiary, numeric: true)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

private struct SegmentedBarGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                SectionCard("Who thought what", trailing: "4 ratings") {
                    SegmentedBar([
                        SegmentedBarSegment(value: 2, color: Reaction.amazing.fill, label: "Amazing", valueText: "2 \u{00B7} 50%"),
                        SegmentedBarSegment(value: 1, color: Reaction.great.fill, label: "Great", valueText: "1 \u{00B7} 25%"),
                        SegmentedBarSegment(value: 1, color: Reaction.meh.fill, label: "Meh", valueText: "1 \u{00B7} 25%"),
                    ], label: "Rating distribution")
                }
                SectionCard("Macronutrients", trailing: "640 kcal") {
                    SegmentedBar([
                        SegmentedBarSegment(value: 96, color: DS.Color.chartSeries1, label: "Protein", valueText: "24 g", detail: "96 kcal"),
                        SegmentedBarSegment(value: 320, color: DS.Color.chartSeries2, label: "Carbohydrates", valueText: "80 g", detail: "320 kcal"),
                        SegmentedBarSegment(value: 216, color: DS.Color.chartSeries5, label: "Fat", valueText: "24 g", detail: "216 kcal"),
                    ])
                }
                SegmentedBar([], showsLegend: false)
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SegmentedBarGallery() }
#Preview("Dark") { SegmentedBarGallery().preferredColorScheme(.dark) }
