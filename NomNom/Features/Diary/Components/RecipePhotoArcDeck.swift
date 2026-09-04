import SwiftUI

/// Arc deck layout for displaying meal and recipe photos in a hero presentation.
/// Cards are mathematically centered horizontally for any number of photos.
struct RecipePhotoArcDeck: View {
    enum PhotoItem: Identifiable, Equatable {
        case remote(String)
        case data(Data)

        var id: String {
            switch self {
            case .remote(let path): return "remote:\(path)"
            case .data(let data): return "data:\(data.hashValue)"
            }
        }
    }

    let items: [PhotoItem]
    var cuisine: String? = nil
    var cardWidth: CGFloat = 144
    var cardHeight: CGFloat = 192
    var onSelectPhoto: ((Int) -> Void)? = nil

    @State private var isFannedOut = false

    private var displayCount: Int {
        min(items.count, 5)
    }

    init(
        photoPaths: [String],
        cuisine: String? = nil,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = photoPaths.map { .remote($0) }
        self.cuisine = cuisine
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onSelectPhoto = onSelectPhoto
    }

    init(
        draft: FoodStore.PhotosDraft,
        cuisine: String? = nil,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = draft.items.map { item in
            switch item {
            case .existing(let path): return .remote(path)
            case .added(_, let data): return .data(data)
            }
        }
        self.cuisine = cuisine
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onSelectPhoto = onSelectPhoto
    }

    init(
        items: [PhotoItem],
        cuisine: String? = nil,
        cardWidth: CGFloat = 144,
        cardHeight: CGFloat = 192,
        onSelectPhoto: ((Int) -> Void)? = nil
    ) {
        self.items = items
        self.cuisine = cuisine
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onSelectPhoto = onSelectPhoto
    }

    var body: some View {
        ZStack {
            if items.isEmpty {
                emptyPlaceholderCard
            } else {
                let total = displayCount
                ForEach(Array(items.prefix(total).enumerated()), id: \.element.id) { index, item in
                    Button {
                        onSelectPhoto?(index)
                    } label: {
                        cardView(for: item)
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
                    .rotationEffect(.degrees(isFannedOut ? cardAngle(index: index, total: total) : 0))
                    .offset(
                        x: isFannedOut ? cardXOffset(index: index, total: total) : 0,
                        y: isFannedOut ? cardYOffset(index: index, total: total) : 0
                    )
                    .scaleEffect(isFannedOut ? cardScale(index: index, total: total) : 0.96)
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
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .task(id: items) {
            guard items.count > 1 else {
                isFannedOut = false
                return
            }
            isFannedOut = false
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.spring(response: 0.48, dampingFraction: 0.74)) {
                isFannedOut = true
            }
        }
    }

    @ViewBuilder
    private func cardView(for item: PhotoItem) -> some View {
        switch item {
        case .remote(let path):
            RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo)
        case .data(let data):
            MealPhoto(data: data, cornerRadius: AppRadius.photo)
        }
    }

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

    // MARK: - Symmetric Centered Arc Math

    private func cardSpacing(total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        return total <= 3 ? 54.0 : max(32.0, min(50.0, 220.0 / CGFloat(total)))
    }

    private func cardAngle(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let maxAngle = min(18.0, Double(total - 1) * 4.8)
        return (rel / max(1.0, mid)) * maxAngle
    }

    private func cardXOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return rel * cardSpacing(total: total)
    }

    private func cardYOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let curve: CGFloat = total <= 3 ? 3.5 : min(3.0, 14.0 / CGFloat(total))
        return (rel * rel) * curve
    }

    private func cardScale(index: Int, total: Int) -> CGFloat {
        if index == 0 { return 1.0 }
        let mid = Double(total - 1) / 2.0
        let rel = abs(Double(index) - mid)
        return max(0.95, 1.0 - (CGFloat(rel) * 0.02))
    }
}
