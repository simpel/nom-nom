import SwiftUI

/// Every time a recipe was cooked (components/Timeline/README.md): a Section headed
/// "N times", then a horizontal rail (`border-thick` `line-strong`) of TimelineItems
/// that scrolls, snapping to each occasion, and bleeds past the gutters. Past items
/// call `onSelect` with their id (open that meal); the current one isn't tappable.
///
/// Place it inside the screen's gutter padding; `bleed` is how far the rail reaches
/// past it on each side (the first tile lines up with the gutter).
struct Timeline: View {
    let occasions: [TimelineOccasion]
    var title: String
    var bleed: CGFloat
    var onSelect: ((AnyHashable) -> Void)?

    init(
        occasions: [TimelineOccasion],
        title: String = "This recipe over time",
        bleed: CGFloat = DS.Spacing.gutter,
        onSelect: ((AnyHashable) -> Void)? = nil
    ) {
        self.occasions = occasions
        self.title = title
        self.bleed = bleed
        self.onSelect = onSelect
    }

    private var countText: String {
        occasions.count == 1 ? "1 time" : "\(occasions.count) times"
    }

    var body: some View {
        DSSection(title, trailing: countText) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DS.Spacing.s3) {
                    ForEach(occasions) { occasion in
                        TimelineItem(occasion: occasion, onSelect: onSelect.map { select in { select(occasion.id) } })
                    }
                }
                .scrollTargetLayout()
                .background(alignment: .top) {
                    Rectangle()
                        .fill(DS.Color.lineStrong)
                        .frame(height: DS.BorderWidth.thick)
                        .padding(.top, (TimelineItem.dotFrame - DS.BorderWidth.thick) / 2)
                        .accessibilityHidden(true)
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, bleed, for: .scrollContent)
            .padding(.horizontal, -bleed)
        }
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
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { TimelineGallery() }
#Preview("Dark") { TimelineGallery().preferredColorScheme(.dark) }
