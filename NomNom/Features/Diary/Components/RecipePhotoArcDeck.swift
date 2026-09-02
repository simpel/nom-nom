import SwiftUI

/// Arc deck layout for displaying recipe photos in a hero presentation.
struct RecipePhotoArcDeck: View {
    enum PhotoItem: Identifiable {
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
    var onSelectPhoto: ((Int) -> Void)? = nil

    init(photoPaths: [String], onSelectPhoto: ((Int) -> Void)? = nil) {
        self.items = photoPaths.map { .remote($0) }
        self.onSelectPhoto = onSelectPhoto
    }

    init(draft: FoodStore.PhotosDraft, onSelectPhoto: ((Int) -> Void)? = nil) {
        self.items = draft.items.map { item in
            switch item {
            case .existing(let path): return .remote(path)
            case .added(_, let data): return .data(data)
            }
        }
        self.onSelectPhoto = onSelectPhoto
    }

    init(items: [PhotoItem], onSelectPhoto: ((Int) -> Void)? = nil) {
        self.items = items
        self.onSelectPhoto = onSelectPhoto
    }

    var body: some View {
        if !items.isEmpty {
            let total = min(items.count, 7) // Show up to 7 cards in arc
            ZStack {
                ForEach(Array(items.prefix(total).enumerated()), id: \.offset) { index, item in
                    Button {
                        onSelectPhoto?(index)
                    } label: {
                        cardView(for: item)
                            .frame(width: 144, height: 192)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                            .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(onSelectPhoto == nil)
                    .rotationEffect(.degrees(cardAngle(index: index, total: total)))
                    .offset(
                        x: cardXOffset(index: index, total: total),
                        y: cardYOffset(index: index, total: total)
                    )
                    .zIndex(Double(total - index))
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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

    // MARK: - Arc Math

    private func cardSpacing(total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        return total <= 3 ? 52.0 : max(30.0, min(48.0, 210.0 / CGFloat(total)))
    }

    private func cardAngle(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let maxAngle = min(18.0, Double(total - 1) * 4.5)
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
}
