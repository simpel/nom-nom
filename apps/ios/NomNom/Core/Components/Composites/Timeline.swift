import SwiftUI

/// Every time a recipe was cooked (components/Timeline/README.md): a horizontal rail
/// (`border-thick` `line-strong`) of TimelineItems that scrolls, snapping to each
/// occasion, and bleeds past the gutters. Past items call `onSelect` with their id
/// (open that meal); the current one isn't tappable.
///
/// - `md` sits in a Section headed `title` (default "This recipe over time") with "N times".
/// - `mini` has no header unless `title` is given and no count — for cards.
///
/// Place it inside the screen's (or card's) padding; `bleed` is how far the rail
/// reaches past it on each side (the first tile lines up with the padding).
struct Timeline: View {
    let occasions: [TimelineOccasion]
    var size: TimelineSize
    var title: String?
    var bleed: CGFloat
    var onSelect: ((AnyHashable) -> Void)?

    init(
        occasions: [TimelineOccasion],
        size: TimelineSize = .md,
        title: String? = nil,
        bleed: CGFloat = DS.Spacing.gutter,
        onSelect: ((AnyHashable) -> Void)? = nil
    ) {
        self.occasions = occasions
        self.size = size
        self.title = title
        self.bleed = bleed
        self.onSelect = onSelect
    }

    private var countText: String {
        occasions.count == 1 ? "1 time" : "\(occasions.count) times"
    }

    var body: some View {
        switch (size, title) {
        case (.md, _):
            DSSection(title ?? "This recipe over time", trailing: countText) { rail }
        case (.mini, let title?):
            DSSection(title) { rail }
        case (.mini, nil):
            rail
        }
    }

    private var rail: some View {
        // README (root): on touch "the platform draws its own" scroll bar; PhotoStrip
        // README: "Never hide the scrollbar outright".
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: size.railSpacing) {
                ForEach(occasions) { occasion in
                    TimelineItem(
                        occasion: occasion,
                        size: size,
                        onSelect: onSelect.map { select in { select(occasion.id) } }
                    )
                }
            }
            .scrollTargetLayout()
            .background(alignment: .top) {
                // README: "The rail bleeds off the right edge" (bundle.css
                // `.nn-timeline::before { right: 0 }`), past the last occasion.
                Rectangle()
                    .fill(DS.Color.lineStrong)
                    .frame(height: DS.BorderWidth.thick)
                    .padding(.top, (size.dotFrame - DS.BorderWidth.thick) / 2)
                    .padding(.trailing, -bleed)
                    .accessibilityHidden(true)
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, bleed, for: .scrollContent)
        .padding(.horizontal, -bleed)
    }
}

private struct TimelineGallery: View {
    private let occasions: [TimelineOccasion] = {
        let day: TimeInterval = 86_400
        let now = Date()
        return [
            TimelineOccasion(id: AnyHashable(1), date: now.addingTimeInterval(-120 * day), score: 0.55, photo: .none(cuisine: "italian")),
            TimelineOccasion(id: AnyHashable(2), date: now.addingTimeInterval(-60 * day), score: 0.4),
            TimelineOccasion(id: AnyHashable(3), date: now.addingTimeInterval(-20 * day), score: nil, photo: .none(cuisine: "italian")),
            TimelineOccasion(id: AnyHashable(4), date: now, score: 0.9, photo: .none(cuisine: "italian"), isCurrent: true),
        ]
    }()

    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    Timeline(occasions: occasions) { _ in }
                    Timeline(occasions: Array(occasions.suffix(1)), title: "Past meals with Taco Night")
                    Timeline(occasions: occasions.reversed(), size: .mini)
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { TimelineGallery() }
#Preview("Dark") { TimelineGallery().preferredColorScheme(.dark) }
