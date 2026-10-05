import SwiftUI
import UIKit

/// The one photo tile, shared by RecipeCard, PhotoStrip, Timeline and RecipeLinkCard:
/// a rounded, centre-cropped photo (or the no-photo tile) with an optional verdict
/// Badge bottom-right, a favourite heart top-right and a `selected` ring.
///
/// `size` is the long edge (xs 80 · sm/md 192 · lg 288) and `format` the shape (square,
/// or 3:4 portrait/landscape); `format` defaults per size (PhotoCardSize.defaultFormat).
///
/// Fallback chain (every source): photo → cuisine category photo → `sunken` tile with
/// a fork-and-knife glyph ("No photo yet" on `sm`/`lg`). The badge shows either way.
///
/// The heart shows whenever `onToggleFavorite` is given (outlined until a favourite);
/// `isFavorite` alone shows it as a read-only marker. Put it on `md` and `lg` tiles.
///
/// ```swift
/// PhotoCard(.meal(meal), size: .xs)
/// PhotoCard(.recipe(recipe), size: .md, fillsWidth: true, badge: .score(0.82),
///           isFavorite: true, onToggleFavorite: { toggle() })
/// ```
struct PhotoCard<Overlay: View>: View {
    let source: PhotoCardSource
    var size: PhotoCardSize
    var format: PhotoCardFormat
    /// Fill the proposed width at the format's aspect ratio (a grid column) instead of its fixed frame.
    var fillsWidth: Bool
    var badge: PhotoCardBadge?
    var isFavorite: Bool
    var onToggleFavorite: (() -> Void)?
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
        format: PhotoCardFormat? = nil,
        fillsWidth: Bool = false,
        badge: PhotoCardBadge? = nil,
        isFavorite: Bool = false,
        onToggleFavorite: (() -> Void)? = nil,
        isSelected: Bool = false,
        accessibilityLabel: String? = nil,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.source = source
        self.size = size
        self.format = format ?? size.defaultFormat
        self.fillsWidth = fillsWidth
        self.badge = badge
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.overlayContent = overlay()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size.radius, style: .continuous)
    }

    private var showsHeart: Bool { onToggleFavorite != nil || isFavorite }

    var body: some View {
        let resolved = source.resolved(in: store)
        frameBase
            .overlay { picture(resolved) }
            .clipShape(shape)
            .dsHairline(radius: size.radius)
            .overlay {
                if isSelected {
                    shape.strokeBorder(DS.Color.primary, lineWidth: DS.BorderWidth.thick)
                }
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
            .overlay(alignment: .topTrailing) {
                if showsHeart {
                    PhotoCardFavorite(isFavorite: isFavorite, onToggle: onToggleFavorite)
                        .padding(size.favoriteInset)
                }
            }
            .task(id: resolved.loadKey) { await load(resolved) }
    }

    @ViewBuilder
    private var frameBase: some View {
        if fillsWidth {
            Color.clear
                .aspectRatio(format.aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(
                width: format.width(longEdge: size.longEdge),
                height: format.height(longEdge: size.longEdge)
            )
        }
    }

    @ViewBuilder
    private func picture(_ resolved: PhotoCardResolvedSource) -> some View {
        if let image = resolved.image ?? (loadedKey == resolved.loadKey ? loadedImage : nil) {
            Image(uiImage: image).resizable().scaledToFill()
        } else if resolved.path != nil, loadedKey != resolved.loadKey {
            // Still loading: the Skeleton ground and sweep, so the cuisine photo doesn't
            // flash first (Skeleton README).
            DS.Color.sunken.skeletonShimmer()
        } else if let asset = resolved.cuisineAsset {
            Image(asset).resizable().scaledToFill()
        } else {
            noPhotoTile
        }
    }

    /// README: "No photo: `sunken` tile, fork-and-knife glyph in `text-tertiary`, 'No
    /// photo yet' (sm, lg)". Glyph `text-xl`, gap `spacing-1` (bundle.css `__none`).
    private var noPhotoTile: some View {
        ZStack {
            DS.Color.sunken
            VStack(spacing: DS.Spacing.s1) {
                Image(systemName: "fork.knife").textStyle(.sansXl, tone: .tertiary)
                if size.showsCaption {
                    Text("No photo yet").textStyle(.sansSm, tone: .tertiary)
                }
            }
        }
    }

    private func accessibilityText(_ resolved: PhotoCardResolvedSource) -> String {
        let hasPhoto = resolved.image != nil || resolved.path != nil || resolved.cuisineAsset != nil
        var parts = [accessibilityLabel ?? (hasPhoto ? "Photo" : "No photo yet")]
        if size.showsBadge, let badge { parts.append(badge.badge.accessibilityLabel ?? badge.badge.text) }
        if isFavorite, onToggleFavorite == nil { parts.append("Favourite") }
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
        format: PhotoCardFormat? = nil,
        fillsWidth: Bool = false,
        badge: PhotoCardBadge? = nil,
        isFavorite: Bool = false,
        onToggleFavorite: (() -> Void)? = nil,
        isSelected: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.init(
            source, size: size, format: format, fillsWidth: fillsWidth, badge: badge, isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite, isSelected: isSelected, accessibilityLabel: accessibilityLabel
        ) { EmptyView() }
    }
}
