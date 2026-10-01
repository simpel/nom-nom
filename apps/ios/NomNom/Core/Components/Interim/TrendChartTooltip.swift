// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The floating card shown while scrubbing a TrendChart: the date, then one
/// row per series (swatch, name, value ×100). A `sm` Card lifted with `shadow-lg`.
struct TrendChartTooltip: View {
    let date: Date
    let entries: [TrendTooltipEntry]

    var body: some View {
        Card(size: .sm, spacing: DS.Spacing.s1_5) {
            Text(date, format: .dateTime.month(.abbreviated).day())
                .textStyle(.sansSm, weight: .semibold)
            ForEach(entries) { entry in
                HStack(spacing: DS.Spacing.s2) {
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .fill(entry.color)
                        .frame(width: DS.Spacing.s3, height: DS.Spacing.s3)
                        .accessibilityHidden(true)
                    Text(entry.name)
                        .textStyle(.sansSm, tone: .secondary)
                        .lineLimit(1)
                    Spacer(minLength: DS.Spacing.s4)
                    Text(Self.format(entry.value))
                        .textStyle(.sansSm, weight: .semibold, numeric: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(minWidth: DS.Spacing.s36)
        .fixedSize()
        .dsShadow(.lg, cornerRadius: DS.Radius.xl3)
    }

    /// A 0–1 value as a whole-number score, or an en dash when missing.
    static func format(_ value: Double?) -> String {
        guard let value else { return "\u{2013}" }
        return "\(Int((value * 100).rounded()))"
    }
}

private struct TrendChartTooltipGallery: View {
    var body: some View {
        TrendChartTooltip(
            date: .now,
            entries: [
                TrendTooltipEntry(id: 0, name: "Average", color: DS.Color.primary, value: 0.82),
                TrendTooltipEntry(id: 1, name: "Anna", color: DS.Color.chartSeries1, value: 0.9),
                TrendTooltipEntry(id: 2, name: "Joel", color: DS.Color.chartSeries2, value: nil),
            ]
        )
        .padding(DS.Spacing.s8)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { TrendChartTooltipGallery() }
#Preview("Dark") { TrendChartTooltipGallery().preferredColorScheme(.dark) }
