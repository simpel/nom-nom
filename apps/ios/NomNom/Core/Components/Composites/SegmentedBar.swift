import SwiftUI

/// A distribution as one bar (components/SegmentedBar/README.md): a segmented Bar and
/// its key. Every key is a swatch and a label, never a Badge.
///
/// - `.inline`: keys wrapped under the bar (`spacing-2` rows, `spacing-4` columns),
///   a `spacing-2.5` swatch at `radius-sm`, the label `sans-sm` secondary.
/// - `.rows`: the breakdown is a RatingList; the bar is its meter, each tier a row
///   (`spacing-3` swatch, `sans-md` label, `serif-xs` tabular figure).
///
/// `title` wraps it in a Section with that SectionHeader (`spacing-3` above the bar).
/// A zero tier keeps its key at full strength; only its figure is `text-tertiary`.
///
/// ```swift
/// SegmentedBar(.reactions(counts), legend: .inline, title: "How the household rated", trailing: "18 ratings")
/// SegmentedBar(.reactions(counts), legend: .rows, format: .percent, title: "How the household rated")
/// ```
struct SegmentedBar: View {
    let segments: [SegmentedBarSegment]
    var legend: SegmentedBarLegend
    var format: SegmentedBarFormat
    var size: SegmentedBarSize
    var label: String?
    var title: String?
    var trailing: String?

    init(
        _ segments: [SegmentedBarSegment],
        legend: SegmentedBarLegend = .none,
        format: SegmentedBarFormat = .count,
        size: SegmentedBarSize = .md,
        label: String? = nil,
        title: String? = nil,
        trailing: String? = nil
    ) {
        self.segments = segments
        self.legend = legend
        self.format = format
        self.size = size
        self.label = label
        self.title = title
        self.trailing = trailing
    }

    private var total: Double { segments.reduce(0) { $0 + max($1.value, 0) } }

    private func figure(_ segment: SegmentedBarSegment) -> String {
        switch format {
        case .count:
            return Int(segment.value.rounded()).formatted()
        case .percent:
            guard total > 0 else { return "0%" }
            return "\(Int((segment.value / total * 100).rounded()))%"
        }
    }

    var body: some View {
        if legend == .rows {
            rowsBreakdown
        } else if let title {
            DSSection(title, trailing: trailing, spacing: DS.Spacing.s3) { stack }
        } else {
            stack
        }
    }

    private var bar: some View {
        Bar(segments: segments.map(\.bar), size: size.bar, label: label ?? title ?? "Distribution")
    }

    /// bundle.css `.nn-segbar { gap: var(--spacing-3) }`.
    private var stack: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            bar
            if legend == .inline {
                WrappingHStack(spacing: DS.Spacing.s4, lineSpacing: DS.Spacing.s2) {
                    ForEach(segments) { key($0) }
                }
            }
        }
    }

    /// bundle.css `.nn-segbar__key` / `__key-label` / `__swatch`.
    private func key(_ segment: SegmentedBarSegment) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .fill(segment.color)
                .frame(width: DS.Spacing.s2_5, height: DS.Spacing.s2_5)
                .accessibilityHidden(true)
            Text(segment.label).textStyle(.sansSm, tone: .secondary, lines: 1)
            Text(figure(segment))
                .textStyle(.sansSm, tone: segment.value > 0 ? .primary : .tertiary, numeric: true, lines: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var rows: [RatingListRow] {
        segments.map {
            RatingListRow(id: $0.id, label: $0.label, value: figure($0), isZero: $0.value <= 0, swatch: $0.color)
        }
    }

    /// README: "SegmentedBar passes its Bar as that list's `bar` and one row per tier."
    @ViewBuilder
    private var rowsBreakdown: some View {
        if let title {
            RatingList(title, trailing: trailing, rows: rows) { bar }
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                bar.padding(.horizontal, DS.Spacing.sectionInset)
                Card(layout: .list) {
                    ForEach(rows) { RatingListValueRow(row: $0) }
                }
            }
        }
    }
}

private struct SegmentedBarGallery: View {
    private let counts: [Reaction: Int] = [.amazing: 2, .great: 1, .meh: 1]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                SegmentedBar(.reactions(counts), legend: .inline, title: "How the household rated", trailing: "4 ratings")
                SegmentedBar(.reactions(counts), legend: .rows, format: .percent, title: "How the household rated")
                Card {
                    SegmentedBar([
                        SegmentedBarSegment(label: "Protein", value: 32, ink: .chart(0)),
                        SegmentedBarSegment(label: "Carbs", value: 48, ink: .chart(1)),
                        SegmentedBarSegment(label: "Fat", value: 20, ink: .chart(2)),
                    ], legend: .inline, format: .percent, label: "Macros")
                }
                SegmentedBar(.reactions(counts), size: .sm, label: "Ratings")
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SegmentedBarGallery() }
#Preview("Dark") { SegmentedBarGallery().preferredColorScheme(.dark) }
