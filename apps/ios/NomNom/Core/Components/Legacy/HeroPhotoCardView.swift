import SwiftUI

/// A standalone visual card element within `HeroPhotoDeckView`.
struct HeroPhotoCardView: View {
    let item: HeroPhotoItem
    var cuisine: String? = nil
    var width: CGFloat = 144
    var height: CGFloat = 192
    var isRecipeDeck: Bool = false
    var badgeText: String? = nil
    var badgeSystemImage: String? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        let card = ZStack(alignment: .topLeading) {
            cardContent
                .frame(width: width, height: height)
                .background(DS.Color.panel)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(isRecipeDeck ? 0.40 : 0.35), lineWidth: 0.5)
                )
                .shadow(
                    color: Color.black.opacity(isRecipeDeck ? 0.12 : 0.16),
                    radius: isRecipeDeck ? 10 : 14,
                    x: 0,
                    y: isRecipeDeck ? 5 : 7
                )

            if let badgeText {
                HeroPhotoBadgeView(text: badgeText, systemImage: badgeSystemImage)
            }
        }

        if let onTap {
            Button(action: onTap) {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch item {
        case .remote(let path, let bucket):
            RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo, bucket: bucket)
        case .local(_, let data):
            MealPhoto(data: data, cornerRadius: AppRadius.photo)
        case .asset(let name):
            Image(name).resizable().scaledToFill()
        case .party(let name):
            ZStack {
                DS.Color.sunken

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(DS.Color.accentSoft)
                            .frame(width: 52, height: 52)

                        Text(String(name.prefix(1)).uppercased())
                            .font(Font.newsreader(.title, weight: .bold))
                            .foregroundStyle(DS.Color.accentText)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Party")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(12)
            }
        case .fallback(let itemCuisine):
            if let cuisineAsset = Cuisine.assetImageName(for: itemCuisine ?? cuisine) {
                Image(cuisineAsset).resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous)
                    .fill(DS.Color.sunken)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
            }
        }
    }
}

/// Subtle capsule badge attached to a deck photo card.
struct HeroPhotoBadgeView: View {
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 9, weight: .bold))
            }
            Text(text).font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.60), in: Capsule())
        .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)
        .padding(8)
        .allowsHitTesting(false)
    }
}
