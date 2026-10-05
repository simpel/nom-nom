import SwiftUI

/// One time a recipe was cooked.
struct TimelineOccasion: Identifiable {
    let id: AnyHashable
    var date: Date
    /// Normalised 0–1 score; drives the verdict Badge (no numeral on the tile). `mini` ignores it.
    var score: Double?
    /// The meal's photo; nil shows the no-photo tile (badge kept).
    var photo: PhotoCardSource?
    /// The meal on screen: `primary` dot, selected tile, "This meal" (`md`).
    var isCurrent: Bool = false
}

/// Timeline's two sizes (components/Timeline/README.md).
enum TimelineSize {
    /// PhotoCard `sm` tiles with the verdict Badge under a "N times" header.
    case md
    /// PhotoCard `xs` squares with the date only, for cards (PartyCard's recent meals).
    case mini

    /// The dot's outer size, ring included (bundle.css `.nn-timeline__dot`,
    /// `box-sizing: border-box`), so Timeline can centre the rail on it.
    var dotFrame: CGFloat { self == .md ? DS.Spacing.s5 : DS.Spacing.s3 }
    /// `md`: a `spacing-1` `bg` ring; `mini`: README "a 2px ring in `panel`".
    var ringWidth: CGFloat { self == .md ? DS.Spacing.s1 : DS.BorderWidth.thick }
    var ringColor: Color { self == .md ? DS.Color.bg : DS.Color.panel }
    var itemSpacing: CGFloat { self == .md ? DS.Spacing.s2_5 : DS.Spacing.s2 }
    var railSpacing: CGFloat { self == .md ? DS.Spacing.s3 : DS.Spacing.s2 }
}

/// A Timeline stop.
/// - `md`: an `s5` dot (current `primary`, past `primary-muted`), a PhotoCard `sm`
///   portrait with the verdict Badge (selected when current), and the date in `sans-sm`
///   ("This meal", semibold, for the current one).
/// - `mini`: an `s3` dot, a PhotoCard `xs` square with no badge, and the date `sans-xs`
///   tertiary tabular; the current one semibold `text-primary`, keeping its date.
struct TimelineItem: View {
    let occasion: TimelineOccasion
    var size: TimelineSize = .md
    var onSelect: (() -> Void)?

    var body: some View {
        if let onSelect, !occasion.isCurrent {
            Button(action: onSelect) { content }
                .buttonStyle(AppPressableButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: size.itemSpacing) {
            Circle()
                .fill(occasion.isCurrent ? DS.Color.primary : DS.Color.primaryMuted)
                .padding(size.ringWidth)
                .frame(width: size.dotFrame, height: size.dotFrame)
                .background(size.ringColor, in: Circle())
                .accessibilityHidden(true)

            tile.accessibilityHidden(true)
            label.lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(occasion.isCurrent ? .isSelected : [])
    }

    @ViewBuilder
    private var tile: some View {
        switch size {
        case .md:
            PhotoCard(
                occasion.photo ?? .none(),
                size: .sm,
                badge: occasion.score.map { .score($0) },
                isSelected: occasion.isCurrent
            )
        case .mini:
            PhotoCard(occasion.photo ?? .none(), size: .xs, format: .square)
        }
    }

    @ViewBuilder
    private var label: some View {
        let shortDate = occasion.date.formatted(.dateTime.day().month(.abbreviated))
        switch size {
        case .md:
            Text(occasion.isCurrent ? "This meal" : shortDate)
                .textStyle(.sansSm, weight: occasion.isCurrent ? .semibold : .normal)
        case .mini:
            Text(shortDate)
                .textStyle(
                    .sansXs,
                    tone: occasion.isCurrent ? .primary : .tertiary,
                    weight: occasion.isCurrent ? .semibold : .normal,
                    numeric: true
                )
        }
    }

    private var accessibilityText: String {
        let when = occasion.isCurrent && size == .md
            ? "This meal"
            : occasion.date.formatted(.dateTime.day().month(.wide).year())
        guard size == .md else { return when }
        guard let score = occasion.score else { return "\(when), not rated" }
        return "\(when), \(Reaction(score: score).shortLabel)"
    }
}
