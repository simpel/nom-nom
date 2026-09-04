import SwiftUI

/// Visual hero displaying an arc of curated category food photos fanning out smoothly.
struct CategoryPhotoArcView: View {
    @State private var isFannedOut = false

    // Curated visually diverse cuisines to display on the arc
    private let cuisines: [Cuisine] = [.french, .italian, .asian, .mexican, .mediterranean]

    private let cardWidth: CGFloat = 86
    private let cardHeight: CGFloat = 114

    var body: some View {
        ZStack {
            ForEach(Array(cuisines.enumerated()), id: \.element) { index, cuisine in
                categoryCard(for: cuisine, at: index, total: cuisines.count)
            }
        }
        .frame(height: 156)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meal categories including \(cuisines.map(\.displayName).joined(separator: ", "))")
        .task {
            guard !isFannedOut else { return }
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
                isFannedOut = true
            }
        }
    }

    // MARK: - Arc Card

    private func categoryCard(for cuisine: Cuisine, at index: Int, total: Int) -> some View {
        let centerIndex = Double(total - 1) / 2.0
        let rel = Double(index) - centerIndex
        let angle = isFannedOut ? rel * 9.5 : 0.0
        let xOffset = isFannedOut ? CGFloat(rel * 50.0) : 0.0
        let yOffset = isFannedOut ? CGFloat(rel * rel * 3.5) : 0.0
        let scale = isFannedOut ? (1.0 - abs(rel) * 0.02) : 1.0
        let zIndex = Double(total) - abs(rel)

        return Image(cuisine.assetImageName)
            .resizable()
            .scaledToFill()
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            .scaleEffect(scale)
            .rotationEffect(.degrees(angle))
            .offset(x: xOffset, y: yOffset)
            .zIndex(zIndex)
    }
}

#Preview {
    NomNomPreview {
        CategoryPhotoArcView()
            .padding(.vertical, 40)
    }
}
