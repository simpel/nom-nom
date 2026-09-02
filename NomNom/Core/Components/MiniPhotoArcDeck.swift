import SwiftUI

/// Mini arc deck layout for displaying meal/recipe photos in compact headers and list rows.
struct MiniPhotoArcDeck: View {
    let photoPaths: [String]
    var cardWidth: CGFloat = 42
    var cardHeight: CGFloat = 54
    var cornerRadius: CGFloat = AppRadius.photo

    var body: some View {
        ZStack {
            if photoPaths.isEmpty {
                emptyCard
            } else {
                let total = min(photoPaths.count, 5)
                ForEach(Array(photoPaths.prefix(total).enumerated()), id: \.offset) { index, path in
                    RemoteMealPhoto(path: path, cornerRadius: cornerRadius)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 2)
                        .rotationEffect(.degrees(cardAngle(index: index, total: total)))
                        .offset(
                            x: cardXOffset(index: index, total: total),
                            y: cardYOffset(index: index, total: total)
                        )
                        .zIndex(Double(total - index))
                }
            }
        }
        .frame(width: cardWidth + 24, height: cardHeight + 8)
    }

    private var emptyCard: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(uiColor: .tertiarySystemFill))
            .frame(width: cardWidth, height: cardHeight)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }

    // MARK: - Arc Math

    private func cardAngle(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = Double(index) - mid
        let maxAngle = min(14.0, Double(total - 1) * 3.8)
        return (rel / max(1.0, mid)) * maxAngle
    }

    private func cardXOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        let spacing: CGFloat = total <= 3 ? 12.0 : max(8.0, 32.0 / CGFloat(total))
        return rel * spacing
    }

    private func cardYOffset(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        let rel = CGFloat(Double(index) - mid)
        return (rel * rel) * 1.5
    }
}
