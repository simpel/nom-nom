import SwiftUI

/// Harmonized hero header presenting:
/// 1. An arced card deck of photos (or cuisine asset / placeholder)
/// 2. Editorial title (using `AppTypography.pageTitleFont`)
/// 3. Formatted date or subtitle (using Inter subheadline)
/// 4. Optional primary action button placed directly beneath the text block
///
/// Designed for reuse across `MealDetailView`, `MealRatingSheet`, `MealVerdictStepView`,
/// `RecipeDetailView`, and any other surface needing this recurring visual signature. Centered by default.
struct ArcHeroHeaderView<ActionContent: View>: View {
    let items: [HeroPhotoItem]
    var recipeItems: [HeroPhotoItem] = []
    var cuisine: String? = nil
    let title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .center
    var onSelectPhoto: ((Int) -> Void)? = nil
    var onSelectMealPhoto: ((Int) -> Void)? = nil
    var onSelectRecipePhoto: ((Int) -> Void)? = nil
    @ViewBuilder var action: () -> ActionContent

    private var hasAction: Bool {
        ActionContent.self != EmptyView.self
    }

    init(
        items: [HeroPhotoItem],
        recipeItems: [HeroPhotoItem] = [],
        cuisine: String? = nil,
        title: String,
        subtitle: String? = nil,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil,
        @ViewBuilder action: @escaping () -> ActionContent
    ) {
        self.items = items
        self.recipeItems = recipeItems
        self.cuisine = cuisine
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
        self.onSelectMealPhoto = onSelectMealPhoto
        self.onSelectRecipePhoto = onSelectRecipePhoto
        self.onSelectPhoto = onSelectPhoto
        self.action = action
    }

    init(
        photoPaths: [String],
        recipePhotoPaths: [String] = [],
        cuisine: String? = nil,
        partyName: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        title: String,
        subtitle: String? = nil,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil,
        @ViewBuilder action: @escaping () -> ActionContent
    ) {
        let photoItems: [HeroPhotoItem]
        if photoPaths.isEmpty && recipePhotoPaths.isEmpty, let partyName, !partyName.isEmpty {
            photoItems = [.party(name: partyName)]
        } else {
            let effectiveBucket = partyName != nil ? SupabaseConfig.partyBucket : bucket
            photoItems = photoPaths.map { .remote(path: $0, bucket: effectiveBucket) }
        }
        self.init(
            items: photoItems,
            recipeItems: recipePhotoPaths.map { .remote(path: $0, bucket: SupabaseConfig.recipeBucket) },
            cuisine: cuisine,
            title: title,
            subtitle: subtitle,
            alignment: alignment,
            onSelectMealPhoto: onSelectMealPhoto,
            onSelectRecipePhoto: onSelectRecipePhoto,
            onSelectPhoto: onSelectPhoto,
            action: action
        )
    }

    var body: some View {
        VStack(alignment: alignment, spacing: DS.Spacing.heroInner) {
            HeroPhotoDeckView(
                items: items,
                recipeItems: recipeItems,
                cuisine: cuisine,
                cardWidth: 144,
                cardHeight: 192,
                onSelectMealPhoto: onSelectMealPhoto,
                onSelectRecipePhoto: onSelectRecipePhoto,
                onSelectPhoto: onSelectPhoto
            )
            .frame(height: 228)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            VStack(alignment: alignment, spacing: 14) {
                PageHeader(
                    title: title,
                    subtitle: subtitle,
                    alignment: alignment
                )

                if hasAction {
                    action()
                }
            }
        }
        .padding(.bottom, bottomPadding)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var bottomPadding: CGFloat {
        hasAction ? 36 : 6
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }
}

extension ArcHeroHeaderView where ActionContent == EmptyView {
    init(
        photoPaths: [String],
        recipePhotoPaths: [String] = [],
        cuisine: String? = nil,
        partyName: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        title: String,
        subtitle: String? = nil,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            photoPaths: photoPaths,
            recipePhotoPaths: recipePhotoPaths,
            cuisine: cuisine,
            partyName: partyName,
            bucket: bucket,
            title: title,
            subtitle: subtitle,
            alignment: alignment,
            onSelectMealPhoto: onSelectMealPhoto,
            onSelectRecipePhoto: onSelectRecipePhoto,
            onSelectPhoto: onSelectPhoto
        ) {
            EmptyView()
        }
    }

    init(
        photoPaths: [String],
        recipePhotoPaths: [String] = [],
        cuisine: String? = nil,
        partyName: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        title: String,
        date: Date,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            photoPaths: photoPaths,
            recipePhotoPaths: recipePhotoPaths,
            cuisine: cuisine,
            partyName: partyName,
            bucket: bucket,
            title: title,
            subtitle: date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()),
            alignment: alignment,
            onSelectMealPhoto: onSelectMealPhoto,
            onSelectRecipePhoto: onSelectRecipePhoto,
            onSelectPhoto: onSelectPhoto
        )
    }

    init(
        items: [HeroPhotoItem],
        recipeItems: [HeroPhotoItem] = [],
        cuisine: String? = nil,
        title: String,
        subtitle: String? = nil,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            items: items,
            recipeItems: recipeItems,
            cuisine: cuisine,
            title: title,
            subtitle: subtitle,
            alignment: alignment,
            onSelectMealPhoto: onSelectMealPhoto,
            onSelectRecipePhoto: onSelectRecipePhoto,
            onSelectPhoto: onSelectPhoto
        ) {
            EmptyView()
        }
    }

    init(
        items: [HeroPhotoItem],
        recipeItems: [HeroPhotoItem] = [],
        cuisine: String? = nil,
        title: String,
        date: Date,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            items: items,
            recipeItems: recipeItems,
            cuisine: cuisine,
            title: title,
            subtitle: date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()),
            alignment: alignment,
            onSelectMealPhoto: onSelectMealPhoto,
            onSelectRecipePhoto: onSelectRecipePhoto,
            onSelectPhoto: onSelectPhoto
        )
    }

    init(
        draft: FoodStore.PhotosDraft,
        recipeItems: [HeroPhotoItem] = [],
        cuisine: String? = nil,
        title: String,
        date: Date,
        alignment: HorizontalAlignment = .center,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil
    ) {
        let mappedItems: [HeroPhotoItem] = draft.items.map { item in
            switch item {
            case .existing(let path):
                return .remote(path: path, bucket: SupabaseConfig.photoBucket)
            case .added(let id, let data):
                return .local(id: id.uuidString, data: data)
            }
        }
        self.init(
            items: mappedItems,
            recipeItems: recipeItems,
            cuisine: cuisine,
            title: title,
            subtitle: date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()),
            alignment: alignment,
            onSelectMealPhoto: onSelectMealPhoto,
            onSelectRecipePhoto: onSelectRecipePhoto
        )
    }
}
