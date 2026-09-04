import SwiftUI

/// Harmonized hero header presenting:
/// 1. An arced card deck of photos (or cuisine asset / placeholder)
/// 2. Editorial title (using `AppTypography.pageTitleFont`)
/// 3. Formatted date or subtitle (using Inter subheadline)
///
/// Designed for reuse across `MealDetailView`, `MealRatingSheet`, `MealVerdictStepView`,
/// and any other surface needing this recurring visual signature. Centered by default.
struct ArcHeroHeaderView: View {
    let items: [HeroPhotoItem]
    var cuisine: String? = nil
    let title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .center
    var onSelectPhoto: ((Int) -> Void)? = nil

    init(
        photoPaths: [String],
        cuisine: String? = nil,
        title: String,
        subtitle: String? = nil,
        alignment: HorizontalAlignment = .center,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = photoPaths.map { .remote(path: $0) }
        self.cuisine = cuisine
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
        self.onSelectPhoto = onSelectPhoto
    }

    init(
        photoPaths: [String],
        cuisine: String? = nil,
        title: String,
        date: Date,
        alignment: HorizontalAlignment = .center,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            photoPaths: photoPaths,
            cuisine: cuisine,
            title: title,
            subtitle: date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()),
            alignment: alignment,
            onSelectPhoto: onSelectPhoto
        )
    }

    init(
        draft: FoodStore.PhotosDraft,
        cuisine: String? = nil,
        title: String,
        date: Date,
        alignment: HorizontalAlignment = .center,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = draft.items.map { item in
            switch item {
            case .existing(let path):
                return .remote(path: path)
            case .added(let id, let data):
                return .local(id: id.uuidString, data: data)
            }
        }
        self.cuisine = cuisine
        self.title = title
        self.subtitle = date.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
        self.alignment = alignment
        self.onSelectPhoto = onSelectPhoto
    }

    var body: some View {
        VStack(alignment: alignment, spacing: DS.Spacing.heroInner) {
            HeroPhotoDeckView(
                items: items,
                cuisine: cuisine,
                onSelectPhoto: onSelectPhoto
            )

            PageHeader(
                title: title,
                subtitle: subtitle,
                alignment: alignment
            )
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }
}
