import SwiftUI

/// The photos at the top of a detail screen: equal PhotoCard `lg` tiles, `s2_5` apart,
/// scrolling sideways and bleeding past both gutters (the first tile lines up with
/// the gutter). With `onAddPhoto`, an "Add photo" button floats `s3` from the strip's
/// bottom-left and collapses to its icon once the strip scrolls more than 8pt.
///
/// Place it inside the screen's gutter padding; `bleed` (default the gutter) is how far
/// it reaches past that padding on each side. Omit `onAddPhoto` for read-only.
///
/// - Empty, can add: a dashed `s20` "Add a photo" tile (the whole tile is the button).
/// - Empty, read-only: a PhotoCard `lg` no-photo tile.
struct PhotoStrip: View {
    let photos: [PhotoCardSource]
    /// Normalised 0–1 score per photo (by index) for its verdict Badge; nil hides it.
    var scores: [Double?]
    var bleed: CGFloat
    /// Force the add button's icon-only state (e.g. the screen itself scrolled).
    var isAddCollapsed: Bool?
    var onAddPhoto: (() -> Void)?
    var onSelect: (Int) -> Void

    @State private var hasScrolled = false

    private static let space = "PhotoStrip"

    init(
        photos: [PhotoCardSource],
        scores: [Double?] = [],
        bleed: CGFloat = DS.Spacing.gutter,
        isAddCollapsed: Bool? = nil,
        onAddPhoto: (() -> Void)? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.photos = photos
        self.scores = scores
        self.bleed = bleed
        self.isAddCollapsed = isAddCollapsed
        self.onAddPhoto = onAddPhoto
        self.onSelect = onSelect
    }

    var body: some View {
        if photos.isEmpty {
            if let onAddPhoto {
                PhotoStripEmptyAddTile(action: onAddPhoto)
            } else {
                PhotoCard(.none(), size: .lg)
            }
        } else {
            strip
        }
    }

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s2_5) {
                ForEach(photos.indices, id: \.self) { index in
                    Button { onSelect(index) } label: {
                        PhotoCard(
                            photos[index],
                            size: .lg,
                            badge: score(at: index).map { .score($0) },
                            accessibilityLabel: "Photo \(index + 1) of \(photos.count)"
                        )
                    }
                    .buttonStyle(AppPressableButtonStyle())
                }
            }
            .onGeometryChange(for: Bool.self) { proxy in
                proxy.frame(in: .named(Self.space)).minX < bleed - DS.Spacing.s2
            } action: { scrolled in
                hasScrolled = scrolled
            }
        }
        .coordinateSpace(.named(Self.space))
        .contentMargins(.horizontal, bleed, for: .scrollContent)
        .overlay(alignment: .bottomLeading) {
            if let onAddPhoto {
                PhotoStripAddButton(isCollapsed: isAddCollapsed ?? hasScrolled, action: onAddPhoto)
                    .padding(.leading, bleed + DS.Spacing.s3)
                    .padding(.bottom, DS.Spacing.s3)
            }
        }
        .padding(.horizontal, -bleed)
    }

    private func score(at index: Int) -> Double? {
        scores.indices.contains(index) ? scores[index] : nil
    }
}

private struct PhotoStripGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    PhotoStrip(
                        photos: [.none(cuisine: "italian"), .none(cuisine: "mexican"), .none(cuisine: "japanese")],
                        scores: [0.9, nil, 0.4],
                        onAddPhoto: {},
                        onSelect: { _ in }
                    )
                    PhotoStrip(photos: [.none(cuisine: "thai"), .none()], onSelect: { _ in })
                    PhotoStrip(photos: [], onAddPhoto: {}, onSelect: { _ in })
                    PhotoStrip(photos: [], onSelect: { _ in })
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PhotoStripGallery() }
#Preview("Dark") { PhotoStripGallery().preferredColorScheme(.dark) }
