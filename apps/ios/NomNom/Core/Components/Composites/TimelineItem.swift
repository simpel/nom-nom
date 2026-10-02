import SwiftUI

/// One time a recipe was cooked.
struct TimelineOccasion: Identifiable {
    let id: AnyHashable
    var date: Date
    /// Normalised 0–1 score; drives the verdict Badge (no numeral on the tile).
    var score: Double?
    /// The meal's photo; nil shows the no-photo tile (badge kept).
    var photo: PhotoCardSource?
    /// The meal on screen: `primary` dot, selected tile, "This meal".
    var isCurrent: Bool = false
}

/// A Timeline stop: an `s5` dot on the rail (`s1` `bg` ring inside it; current `primary`, past
/// `primary-muted`), a PhotoCard `sm` portrait (`s36` × `s48`) with the verdict Badge
/// (selected when current), and the date in `sans-sm` ("This meal", semibold, for the
/// current one). No score numeral: the Badge carries the result, the score its tooltip.
struct TimelineItem: View {
    let occasion: TimelineOccasion
    var onSelect: (() -> Void)?

    /// The dot's outer size, ring included (bundle.css `.nn-timeline__dot`: `spacing-5`,
    /// `box-sizing: border-box`), so Timeline can centre the rail on it.
    static let dotFrame = DS.Spacing.s5

    var body: some View {
        if let onSelect, !occasion.isCurrent {
            Button(action: onSelect) { content }
                .buttonStyle(AppPressableButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        // bundle.css `.nn-timeline__item { gap: var(--spacing-2\.5) }`, a start-aligned
        // column (the dot and the date sit at the tile's leading edge).
        VStack(alignment: .leading, spacing: DS.Spacing.s2_5) {
            // A `spacing-5` dot whose `spacing-1` `bg` ring is inside that size.
            Circle()
                .fill(occasion.isCurrent ? DS.Color.primary : DS.Color.primaryMuted)
                .padding(DS.Spacing.s1)
                .frame(width: Self.dotFrame, height: Self.dotFrame)
                .background(DS.Color.bg, in: Circle())
                .accessibilityHidden(true)

            PhotoCard(
                occasion.photo ?? .none(),
                size: .sm,
                badge: occasion.score.map { .score($0) },
                isSelected: occasion.isCurrent
            )
            .accessibilityHidden(true)

            Text(occasion.isCurrent ? "This meal" : occasion.date.formatted(.dateTime.day().month(.abbreviated)))
                .textStyle(.sansSm, weight: occasion.isCurrent ? .semibold : .normal)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(occasion.isCurrent ? .isSelected : [])
    }

    private var accessibilityText: String {
        let when = occasion.isCurrent
            ? "This meal"
            : occasion.date.formatted(.dateTime.day().month(.wide).year())
        guard let score = occasion.score else { return "\(when), not rated" }
        return "\(when), \(Reaction(score: score).shortLabel)"
    }
}
