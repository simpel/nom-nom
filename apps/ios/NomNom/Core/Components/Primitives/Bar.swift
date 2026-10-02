import SwiftUI

/// Bar thicknesses: `xs` 4 · `sm` 6 · `md` 8 · `lg` 10 · `xl` 12 (`spacing-1` … `spacing-3`).
/// `xs` under a section header, `md` in a card, `lg`/`xl` only when the bar is the subject.
enum BarSize: Equatable, CaseIterable {
    case xs, sm, md, lg, xl

    var height: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s1
        case .sm: return DS.Spacing.s1_5
        case .md: return DS.Spacing.s2
        case .lg: return DS.Spacing.s2_5
        case .xl: return DS.Spacing.s3
        }
    }
}

/// One block of a segmented Bar. Width is its share of the sum (or of the Bar's `max`).
struct BarSegment {
    /// What paints the block. A block with no ink is `primary`.
    enum Ink {
        /// The reaction ramp: taste distributions only.
        case reaction(Reaction)
        /// `chart-series{n}` by a stable, zero-based index, never cycled.
        case chart(Int)
        /// Any other colour token.
        case color(Color)
    }

    let value: Double
    var ink: Ink?
    /// What the block stands for; the visible key is SegmentedBar's job.
    var label: String?

    init(value: Double, ink: Ink? = nil, label: String? = nil) {
        self.value = value
        self.ink = ink
        self.label = label
    }

    var color: Color {
        switch ink {
        case .reaction(let reaction): return reaction.fill
        case .chart(let index):
            let series = DS.Color.chartSeries
            return series.indices.contains(index) ? series[index] : DS.Color.primary
        case .color(let color): return color
        case nil: return DS.Color.primary
        }
    }
}

/// The one bar: a read-only horizontal meter holding one fill or several blocks.
/// Ground `track`, corners `radius-full`, blocks split by a 1pt `panel` seam.
/// A bar carries no text; the number lives beside it (ScoreValue, a SectionHeader figure).
///
/// ```swift
/// Bar(value: 83)                                        // a score
/// Bar(value: 5, max: 6, size: .xs, label: "5 of 6 rated")
/// Bar(segments: tiers, size: .lg, label: "How the household rated")
/// ```
struct Bar: View {
    private let value: Double?
    private let segments: [BarSegment]?
    private let max: Double?
    private let size: BarSize
    private let label: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A single fill, `0…max`; `nil` draws an empty track ("Not rated").
    init(value: Double?, max: Double = 100, size: BarSize = .md, label: String? = nil) {
        self.value = value
        self.segments = nil
        self.max = max
        self.size = size
        self.label = label
    }

    /// Several blocks. With `max` the blocks are sized against it, leaving a remainder of track.
    init(segments: [BarSegment], max: Double? = nil, size: BarSize = .md, label: String) {
        self.value = nil
        self.segments = segments
        self.max = max
        self.size = size
        self.label = label
    }

    private var blocks: [BarSegment] {
        if let segments { return segments.filter { $0.value > 0 } }
        guard let value else { return [] }
        return [BarSegment(value: value)]
    }

    private var total: Double {
        if let max, max > 0 { return max }
        return blocks.reduce(0) { $0 + $1.value }
    }

    private func fraction(_ block: BarSegment) -> Double {
        guard total > 0 else { return 0 }
        return Swift.min(Swift.max(block.value / total, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                    Rectangle()
                        .fill(block.color)
                        .frame(width: proxy.size.width * fraction(block))
                        .overlay(alignment: .leading) {
                            if index > 0 {
                                Rectangle()
                                    .fill(DS.Color.panel)
                                    .frame(width: DS.BorderWidth.hairline)
                            }
                        }
                }
            }
            .frame(width: proxy.size.width, alignment: .leading)
        }
        .frame(height: size.height)
        .frame(maxWidth: .infinity)
        .background(DS.Color.track)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.full, style: .continuous))
        .animation(reduceMotion ? nil : DS.Motion.layout, value: blocks.map(fraction))
        .modifier(BarAccessibility(isSegmented: segments != nil, label: label, value: valueText))
    }

    private var valueText: String {
        if segments != nil {
            return blocks.map { "\($0.label ?? "") \(Int((fraction($0) * 100).rounded())) percent" }
                .joined(separator: ", ")
        }
        guard let value, let max else { return "Not rated" }
        return "\(Int(value.rounded())) out of \(Int(max.rounded()))"
    }
}

/// A single fill reads as a meter (label + "x out of max"); a segmented bar as a labelled image.
private struct BarAccessibility: ViewModifier {
    let isSegmented: Bool
    let label: String?
    let value: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label ?? value)
            .accessibilityValue(label == nil ? "" : value)
            .accessibilityAddTraits(isSegmented ? .isImage : [])
    }
}

private struct BarGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            ForEach(BarSize.allCases, id: \.self) { Bar(value: 64, size: $0) }
            Bar(value: 5, max: 6, size: .xs, label: "5 of 6 rated")
            Bar(value: nil)
            Bar(segments: [
                BarSegment(value: 2, ink: .reaction(.amazing), label: "Amazing"),
                BarSegment(value: 1, ink: .reaction(.great), label: "Great"),
                BarSegment(value: 1, ink: .reaction(.meh), label: "Meh"),
            ], size: .lg, label: "How the household rated")
            Bar(segments: [
                BarSegment(value: 3, ink: .chart(0), label: "Protein"),
                BarSegment(value: 1, ink: .chart(1), label: "Carbohydrates"),
            ], max: 10, size: .xl, label: "4 of 10 rated")
        }
        .padding(DS.Spacing.s4)
        .background(DS.Color.panel)
    }
}

#Preview("Light") { BarGallery() }
#Preview("Dark") { BarGallery().preferredColorScheme(.dark) }
