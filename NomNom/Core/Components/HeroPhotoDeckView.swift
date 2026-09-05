import SwiftUI

/// Recurrent hero UX moment presenting asset images as a crafted deck of cards.
///
/// When both meal and recipe photos are provided, displays a dual-layer arc:
/// - Foreground arc: Meal photos at primary scale and angle
/// - Background arc: Recipe photos layered behind at a distinct angle, size, and lift
struct HeroPhotoDeckView: View {
    let items: [HeroPhotoItem]
    var recipeItems: [HeroPhotoItem] = []
    var cuisine: String? = nil
    var bucket: String = SupabaseConfig.photoBucket
    var cardWidth: CGFloat = 144
    var cardHeight: CGFloat = 192
    var badgeText: String? = nil
    var badgeSystemImage: String? = nil
    var onSelectPhoto: ((Int) -> Void)? = nil
    var onSelectMealPhoto: ((Int) -> Void)? = nil
    var onSelectRecipePhoto: ((Int) -> Void)? = nil

    @State private var isFannedOut = false

    private var hasDualDeck: Bool {
        !items.isEmpty && !recipeItems.isEmpty
    }

    private var displayMealCount: Int { min(items.count, 5) }
    private var displayRecipeCount: Int { min(recipeItems.count, 5) }

    init(
        photoPaths: [String],
        recipePhotoPaths: [String] = [],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        badgeText: String? = nil,
        badgeSystemImage: String? = nil,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = photoPaths.map { .remote(path: $0, bucket: bucket) }
        self.recipeItems = recipePhotoPaths.map { .remote(path: $0, bucket: SupabaseConfig.recipeBucket) }
        self.cuisine = cuisine
        self.bucket = bucket
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.badgeText = badgeText
        self.badgeSystemImage = badgeSystemImage
        self.onSelectPhoto = onSelectPhoto
        self.onSelectMealPhoto = onSelectMealPhoto
        self.onSelectRecipePhoto = onSelectRecipePhoto
    }

    init(
        photoPaths: [String],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        badgeText: String? = nil,
        badgeSystemImage: String? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            photoPaths: photoPaths,
            recipePhotoPaths: [],
            cuisine: cuisine,
            bucket: bucket,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            badgeText: badgeText,
            badgeSystemImage: badgeSystemImage,
            onSelectPhoto: onSelectPhoto
        )
    }

    init(
        items: [HeroPhotoItem],
        recipeItems: [HeroPhotoItem] = [],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        badgeText: String? = nil,
        badgeSystemImage: String? = nil,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = items
        self.recipeItems = recipeItems
        self.cuisine = cuisine
        self.bucket = bucket
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.badgeText = badgeText
        self.badgeSystemImage = badgeSystemImage
        self.onSelectPhoto = onSelectPhoto
        self.onSelectMealPhoto = onSelectMealPhoto
        self.onSelectRecipePhoto = onSelectRecipePhoto
    }

    init(
        items: [HeroPhotoItem],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        badgeText: String? = nil,
        badgeSystemImage: String? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.init(
            items: items,
            recipeItems: [],
            cuisine: cuisine,
            bucket: bucket,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            badgeText: badgeText,
            badgeSystemImage: badgeSystemImage,
            onSelectPhoto: onSelectPhoto
        )
    }

    init(
        draft: FoodStore.PhotosDraft,
        recipeItems: [HeroPhotoItem] = [],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        badgeText: String? = nil,
        badgeSystemImage: String? = nil,
        onSelectMealPhoto: ((Int) -> Void)? = nil,
        onSelectRecipePhoto: ((Int) -> Void)? = nil,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = draft.items.map { item in
            switch item {
            case .existing(let path):
                return .remote(path: path, bucket: bucket)
            case .added(let id, let data):
                return .local(id: id.uuidString, data: data)
            }
        }
        self.recipeItems = recipeItems
        self.cuisine = cuisine
        self.bucket = bucket
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.badgeText = badgeText
        self.badgeSystemImage = badgeSystemImage
        self.onSelectPhoto = onSelectPhoto
        self.onSelectMealPhoto = onSelectMealPhoto
        self.onSelectRecipePhoto = onSelectRecipePhoto
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if items.isEmpty && recipeItems.isEmpty {
                emptyPlaceholderCard
            } else if hasDualDeck {
                dualDeckView
            } else if !items.isEmpty {
                singleDeckView(for: items, isRecipeDeck: false)
            } else {
                singleDeckView(for: recipeItems, isRecipeDeck: true)
            }
        }
        .frame(height: cardHeight + 28, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .task(id: "\(items.count)-\(recipeItems.count)") {
            guard (items.count + recipeItems.count) > 1 else {
                isFannedOut = false
                return
            }
            isFannedOut = false
            try? await Task.sleep(nanoseconds: 180_000_000)
            withAnimation(.spring(response: 0.52, dampingFraction: 0.72)) {
                isFannedOut = true
            }
        }
    }

    // MARK: - Dual Deck Layout (Meal left-tilted, Recipe right-tilted, bottom-aligned)

    private var dualDeckView: some View {
        let mealTotal = displayMealCount
        let recipeTotal = displayRecipeCount

        return ZStack(alignment: .bottom) {
            // 1. Right Wing Arc (Recipe Deck, way smaller, tilted right, layered behind)
            ForEach(Array(recipeItems.prefix(recipeTotal).enumerated()), id: \.element.id) { index, item in
                cardView(for: item, index: index, isRecipeDeck: true)
                    .scaleEffect(HeroDeckMath.dualRecipeScale(for: index, total: recipeTotal, isFannedOut: isFannedOut), anchor: .bottom)
                    .rotationEffect(.degrees(HeroDeckMath.dualRecipeRotationAngle(for: index, total: recipeTotal, isFannedOut: isFannedOut)), anchor: .bottom)
                    .offset(
                        x: HeroDeckMath.dualRecipeXOffset(for: index, total: recipeTotal, isFannedOut: isFannedOut),
                        y: HeroDeckMath.dualRecipeYOffset(for: index, total: recipeTotal, isFannedOut: isFannedOut)
                    )
                    .zIndex(Double(recipeTotal - index))
            }

            // 2. Left Wing Arc (Meal Deck, prominent, tilted left, layered slightly over)
            ForEach(Array(items.prefix(mealTotal).enumerated()), id: \.element.id) { index, item in
                cardView(for: item, index: index, isRecipeDeck: false)
                    .scaleEffect(HeroDeckMath.dualMealScale(for: index, total: mealTotal, isFannedOut: isFannedOut), anchor: .bottom)
                    .rotationEffect(.degrees(HeroDeckMath.dualMealRotationAngle(for: index, total: mealTotal, isFannedOut: isFannedOut)), anchor: .bottom)
                    .offset(
                        x: HeroDeckMath.dualMealXOffset(for: index, total: mealTotal, isFannedOut: isFannedOut),
                        y: HeroDeckMath.dualMealYOffset(for: index, total: mealTotal, isFannedOut: isFannedOut)
                    )
                    .zIndex(100 + Double(mealTotal - index))
            }
        }
    }

    // MARK: - Single Deck Layout

    private func singleDeckView(for deckItems: [HeroPhotoItem], isRecipeDeck: Bool) -> some View {
        let total = min(deckItems.count, 5)
        return ZStack {
            ForEach(Array(deckItems.prefix(total).enumerated()), id: \.element.id) { index, item in
                cardView(for: item, index: index, isRecipeDeck: isRecipeDeck)
                    .rotationEffect(.degrees(HeroDeckMath.rotationAngle(for: index, total: total, isFannedOut: isFannedOut)))
                    .offset(
                        x: HeroDeckMath.xOffset(for: index, total: total, isFannedOut: isFannedOut),
                        y: HeroDeckMath.yOffset(for: index, total: total, isFannedOut: isFannedOut)
                    )
                    .scaleEffect(HeroDeckMath.scale(for: index, total: total, isFannedOut: isFannedOut))
                    .zIndex(Double(total - index))
            }
        }
    }

    // MARK: - Subviews

    private var emptyPlaceholderCard: some View {
        cardView(for: .fallback(cuisine: cuisine), index: 0, isRecipeDeck: false)
    }

    private func cardView(for item: HeroPhotoItem, index: Int, isRecipeDeck: Bool) -> some View {
        HeroPhotoCardView(
            item: item,
            cuisine: cuisine,
            width: cardWidth,
            height: cardHeight,
            isRecipeDeck: isRecipeDeck,
            badgeText: index == 0 && !isRecipeDeck ? badgeText : nil,
            badgeSystemImage: badgeSystemImage,
            onTap: action(for: index, isRecipeDeck: isRecipeDeck)
        )
    }

    private func action(for index: Int, isRecipeDeck: Bool) -> (() -> Void)? {
        if isRecipeDeck {
            if let onSelectRecipePhoto { return { onSelectRecipePhoto(index) } }
            if let onSelectPhoto { return { onSelectPhoto(index) } }
        } else {
            if let onSelectMealPhoto { return { onSelectMealPhoto(index) } }
            if let onSelectPhoto { return { onSelectPhoto(index) } }
        }
        return nil
    }
}
