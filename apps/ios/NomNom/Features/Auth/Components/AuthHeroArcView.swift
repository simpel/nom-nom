import SwiftUI

/// Hero visual for the auth / welcome screen featuring the app icon centered in front,
/// with an arc of smaller category cuisine cards fanning out behind it.
struct AuthHeroArcView: View {
    @State private var isFannedOut = false

    // Curated visually diverse cuisines to display on the arc
    private let cuisines: [Cuisine] = [.italian, .asian, .mexican, .french]

    var body: some View {
        ZStack {
            // Arc of background category cards
            ForEach(Array(cuisines.enumerated()), id: \.element) { index, cuisine in
                categoryCard(for: cuisine, at: index, total: cuisines.count)
            }

            // Central prominent app icon
            appIconView
        }
        .frame(height: 148)
        .padding(.vertical, DS.Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                isFannedOut = true
            }
        }
    }

    // MARK: - Central App Icon

    private var appIconView: some View {
        Image("AppIconImage")
            .resizable()
            .scaledToFill()
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
            .zIndex(10)
    }

    // MARK: - Arc Category Card

    private func categoryCard(for cuisine: Cuisine, at index: Int, total: Int) -> some View {
        let fraction = total > 1 ? (Double(index) / Double(total - 1)) - 0.5 : 0.0
        let angle = isFannedOut ? fraction * 36.0 : 0.0
        let xOffset = isFannedOut ? CGFloat(fraction * 170.0) : 0.0
        let yOffset = isFannedOut ? CGFloat(abs(fraction) * 14.0) : 0.0

        return Image(cuisine.assetImageName)
            .resizable()
            .scaledToFill()
            .frame(width: 66, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(DS.Color.line.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            .rotationEffect(.degrees(angle))
            .offset(x: xOffset, y: yOffset)
            .zIndex(Double(index < total / 2 ? index : total - 1 - index))
    }
}
