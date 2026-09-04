import SwiftUI

/// An individual photo source displayed in `HeroPhotoDeckView`.
enum HeroPhotoItem: Equatable, Identifiable {
    case remote(path: String)
    case local(id: String, data: Data)

    var id: String {
        switch self {
        case .remote(let path): return "remote:\(path)"
        case .local(let id, _): return "local:\(id)"
        }
    }
}

/// Recurrent hero UX moment presenting asset images as a crafted deck of cards.
///
/// On appear, the cover photo is displayed first front-and-center, and the
/// underlying cards animate out smoothly from beneath it into a balanced fan deck.
struct HeroPhotoDeckView: View {
    let items: [HeroPhotoItem]
    var cuisine: String? = nil
    var bucket: String = SupabaseConfig.photoBucket
    var cardWidth: CGFloat = 154
    var cardHeight: CGFloat = 206
    var onSelectPhoto: ((Int) -> Void)? = nil

    @State private var isFannedOut = false

    private var displayCount: Int {
        min(items.count, 5)
    }

    init(
        photoPaths: [String],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 154,
        cardHeight: CGFloat = 206,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = photoPaths.map { .remote(path: $0) }
        self.cuisine = cuisine
        self.bucket = bucket
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onSelectPhoto = onSelectPhoto
    }

    init(
        items: [HeroPhotoItem],
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 154,
        cardHeight: CGFloat = 206,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = items
        self.cuisine = cuisine
        self.bucket = bucket
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onSelectPhoto = onSelectPhoto
    }

    init(
        draft: FoodStore.PhotosDraft,
        cuisine: String? = nil,
        bucket: String = SupabaseConfig.photoBucket,
        cardWidth: CGFloat = 154,
        cardHeight: CGFloat = 206,
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
        self.bucket = bucket
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onSelectPhoto = onSelectPhoto
    }

    var body: some View {
        ZStack {
            if items.isEmpty {
                emptyPlaceholderCard
            } else if items.count == 1 {
                cardView(for: items[0], index: 0)
            } else {
                multiCardDeck
            }
        }
        .frame(height: 248)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.heroDeckPadding)
        .task(id: items) {
            guard items.count > 1 else {
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

    // MARK: - Single & Empty Cards

    private var emptyPlaceholderCard: some View {
        ZStack {
            if let cuisineAsset = Cuisine.assetImageName(for: cuisine) {
                Image(cuisineAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(DS.Color.sunken)
                    .frame(width: cardWidth, height: cardHeight)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                            .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                    )
            }
        }
        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func cardContent(for item: HeroPhotoItem) -> some View {
        switch item {
        case .remote(let path):
            RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo, bucket: bucket)
        case .local(_, let data):
            MealPhoto(data: data, cornerRadius: AppRadius.photo)
        }
    }

    private func cardView(for item: HeroPhotoItem, index: Int) -> some View {
        Button {
            onSelectPhoto?(index)
        } label: {
            cardContent(for: item)
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(onSelectPhoto == nil)
    }

    // MARK: - Multi-Card Deck

    private var multiCardDeck: some View {
        let total = displayCount
        return ZStack {
            ForEach(Array(items.prefix(total).enumerated()), id: \.element.id) { index, item in
                cardView(for: item, index: index)
                    .rotationEffect(.degrees(rotationAngle(for: index, total: total)))
                    .offset(x: xOffset(for: index, total: total), y: yOffset(for: index, total: total))
                    .scaleEffect(scale(for: index, total: total))
                    .zIndex(Double(total - index))
            }

            if items.count > 1 {
                VStack {
                    Spacer()
                    Text("\(items.count) photos")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.60), in: Capsule())
                        .shadow(color: .black.opacity(0.20), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 2)
                }
                .allowsHitTesting(false)
                .zIndex(150)
            }
        }
    }

    // MARK: - Symmetric Centered Arc Math

    private func cardSpacing(total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        return total <= 3 ? 54.0 : max(32.0, min(50.0, 220.0 / CGFloat(total)))
    }

    private func rotationAngle(for index: Int, total: Int) -> Double {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let maxAngle = min(18.0, Double(total - 1) * 4.8)
        return (rel / max(1.0, mid)) * maxAngle
    }

    private func xOffset(for index: Int, total: Int) -> CGFloat {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return rel * cardSpacing(total: total)
    }

    private func yOffset(for index: Int, total: Int) -> CGFloat {
        guard isFannedOut && total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let curve: CGFloat = total <= 3 ? 3.5 : min(3.0, 14.0 / CGFloat(total))
        return (rel * rel) * curve
    }

    private func scale(for index: Int, total: Int) -> CGFloat {
        if index == 0 { return 1.0 }
        if !isFannedOut { return 0.96 }
        let mid = Double(total - 1) / 2.0
        let rel = abs(Double(index) - mid)
        return max(0.95, 1.0 - (CGFloat(rel) * 0.02))
    }
}
