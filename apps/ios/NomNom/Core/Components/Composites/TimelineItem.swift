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

/// A Timeline stop: an `s5` dot on the rail (4pt `bg` ring), a PhotoCard `sm` with the
/// verdict Badge, and the date in `sans-sm` ("This meal", semibold, for the current one).
struct TimelineItem: View {
    let occasion: TimelineOccasion
    var onSelect: (() -> Void)?

    /// Dot plus its ring, so Timeline can centre the rail on it.
    static let dotFrame = DS.Spacing.s5 + DS.Spacing.s1 * 2

    var body: some View {
        if let onSelect, !occasion.isCurrent {
            Button(action: onSelect) { content }
                .buttonStyle(AppPressableButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: DS.Spacing.s2) {
            Circle()
                .fill(occasion.isCurrent ? DS.Color.primary : DS.Color.primaryMuted)
                .frame(width: DS.Spacing.s5, height: DS.Spacing.s5)
                .padding(DS.Spacing.s1)
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
                .textStyle(.sansSm, weight: occasion.isCurrent ? .semibold : .regular)
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
