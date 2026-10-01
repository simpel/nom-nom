import SwiftUI
import UIKit

/// The one photo tile, shared by RecipeCard, PhotoStrip, Timeline and RecipeLinkCard:
/// a rounded, centre-cropped photo (or the no-photo tile) with an optional verdict
/// Badge bottom-right, a favourite heart top-right and a `selected` ring.
///
/// Fallback chain (every source): photo → cuisine category photo → `sunken` tile with
/// a fork-and-knife glyph ("No photo yet" on `sm`/`lg`). The badge shows either way.
///
/// ```swift
/// PhotoCard(.meal(meal), size: .xs)
/// PhotoCard(.recipe(recipe), size: .md, fillsWidth: true, badge: .score(0.82), isFavorite: true)
/// ```
struct PhotoCard<Overlay: View>: View {
    let source: PhotoCardSource
    var size: PhotoCardSize
    /// Fill the proposed width at the size's aspect ratio (a grid column) instead of its fixed frame.
    var fillsWidth: Bool
    var badge: PhotoCardBadge?
    var isFavorite: Bool
    /// 2pt `primary` ring (the current meal in a Timeline).
    var isSelected: Bool
    /// What the photo shows; defaults to "Photo" / "No photo yet".
    var accessibilityLabel: String?
    @ViewBuilder var overlayContent: Overlay

    @Environment(FoodStore.self) private var store: FoodStore?
    @State private var loadedImage: UIImage?
    @State private var loadedKey: String?

    init(
        _ source: PhotoCardSource,
        size: PhotoCardSize = .md,
        fillsWidth: Bool = false,
        badge: PhotoCardBadge? = nil,
        isFavorite: Bool = false,
        isSelected: Bool = false,
        accessibilityLabel: String? = nil,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.source = source
        self.size = size
        self.fillsWidth = fillsWidth
        self.badge = badge
        self.isFavorite = isFavorite
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.overlayContent = overlay()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size.radius, style: .continuous)
    }

    var body: some View {
        let resolved = source.resolved(in: store)
        frameBase
            .overlay { picture(resolved) }
            .clipShape(shape)
            .dsHairline(radius: size.radius)
            .overlay {
                if isSelected {
                    shape.strokeBorder(DS.Color.primary, lineWidth: DS.Spacing.s0_5)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isFavorite { favoriteHeart }
            }
            .overlay(alignment: .bottomTrailing) {
                if size.showsBadge, let badge {
                    badge.badge.padding(size.badgeInset)
                }
            }
            .contentShape(shape)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText(resolved))
            .accessibilityAddTraits(.isImage)
            .overlay { overlayContent }
            .task(id: resolved.loadKey) { await load(resolved) }
    }

    @ViewBuilder
    private var frameBase: some View {
        if fillsWidth {
            Color.clear
                .aspectRatio(size.aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private func picture(_ resolved: PhotoCardResolvedSource) -> some View {
        if let image = resolved.image ?? (loadedKey == resolved.loadKey ? loadedImage : nil) {
            Image(uiImage: image).resizable().scaledToFill()
        } else if resolved.path != nil, loadedKey != resolved.loadKey {
            // Still loading: a quiet ground, so the cuisine photo doesn't flash first.
            DS.Color.sunken
        } else if let asset = resolved.cuisineAsset {
            Image(asset).resizable().scaledToFill()
        } else {
            noPhotoTile
        }
    }

    private var noPhotoTile: some View {
        ZStack {
            DS.Color.sunken
            VStack(spacing: DS.Spacing.s1_5) {
                Image(systemName: "fork.knife").textStyle(size.glyphStyle, tone: .tertiary)
                if size.showsCaption {
                    Text("No photo yet").textStyle(.sansSm, tone: .tertiary)
                }
            }
            .padding(DS.Spacing.s2)
        }
    }

    private var favoriteHeart: some View {
        Image(systemName: "heart.fill")
            .textStyle(.sansXs, tone: nil, weight: .semibold)
            .foregroundStyle(DS.Color.onPhoto)
            .frame(width: DS.Spacing.s6, height: DS.Spacing.s6)
            .background(DS.Color.photoDisc, in: Circle())
            .padding(DS.Spacing.s2)
    }

    private func accessibilityText(_ resolved: PhotoCardResolvedSource) -> String {
        let hasPhoto = resolved.image != nil || resolved.path != nil || resolved.cuisineAsset != nil
        var parts = [accessibilityLabel ?? (hasPhoto ? "Photo" : "No photo yet")]
        if size.showsBadge, let badge { parts.append(badge.badge.accessibilityLabel ?? badge.badge.text) }
        if isFavorite { parts.append("Favourite") }
        return parts.joined(separator: ", ")
    }

    private func load(_ resolved: PhotoCardResolvedSource) async {
        guard let path = resolved.path, let key = resolved.loadKey else {
            loadedImage = nil
            loadedKey = nil
            return
        }
        if loadedKey == key { return }
        let data = await PhotoCache.shared.data(for: path, bucket: resolved.bucket)
        guard !Task.isCancelled else { return }
        loadedImage = data.flatMap(UIImage.init(data:))
        loadedKey = key
    }
}

extension PhotoCard where Overlay == EmptyView {
    init(
        _ source: PhotoCardSource,
        size: PhotoCardSize = .md,
        fillsWidth: Bool = false,
        badge: PhotoCardBadge? = nil,
        isFavorite: Bool = false,
        isSelected: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.init(
            source, size: size, fillsWidth: fillsWidth, badge: badge, isFavorite: isFavorite,
            isSelected: isSelected, accessibilityLabel: accessibilityLabel
        ) { EmptyView() }
    }
}

private struct PhotoCardGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) { store in
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    HStack(alignment: .top, spacing: DS.Spacing.s3) {
                        PhotoCard(.none(cuisine: "italian"), size: .xs)
                        PhotoCard(.none(), size: .xs)
                        if let meal = store.meals.first { PhotoCard(.meal(meal), size: .xs) }
                    }
                    HStack(alignment: .top, spacing: DS.Spacing.s3) {
                        PhotoCard(.none(cuisine: "mexican"), size: .sm, badge: .score(0.9), isSelected: true)
                        PhotoCard(.none(), size: .sm, badge: .reaction(.meh))
                    }
                    PhotoCard(.none(cuisine: "japanese"), size: .md, badge: .score(0.75), isFavorite: true)
                    PhotoCard(.none(), size: .lg, badge: .custom(Badge("Cover", variant: .secondary, appearance: .elevated, size: .sm)))
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PhotoCardGallery() }
#Preview("Dark") { PhotoCardGallery().preferredColorScheme(.dark) }
