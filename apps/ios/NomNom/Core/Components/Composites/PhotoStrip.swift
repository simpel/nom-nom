import SwiftUI

/// The photos at the top of a detail screen (components/PhotoStrip/README.md): equal
/// PhotoCard `lg` tiles in one `format`, `s2_5` apart, scrolling sideways and bleeding
/// past the gutter (the first tile lines up with it). With `onAddPhoto`, an "Add photo"
/// button sits `s3` from the strip's bottom-left and collapses to its icon once the
/// strip scrolls more than 8pt.
///
/// Format is a property of the strip, not of a photo: every tile gets the same one
/// (`portrait` 216×288 by default, `square` 288×288, `landscape` 288×216).
///
/// Place it inside the screen's gutter padding; `bleed` (default the gutter) is how far
/// it reaches past that padding on each side. Omit `onAddPhoto` for read-only.
///
/// - Empty, can add: a dashed "Add a photo" tile (`s20`, `s24` when landscape).
/// - Empty, read-only: a PhotoCard `lg` no-photo tile.
struct PhotoStrip: View {
    let photos: [PhotoCardSource]
    /// Normalised 0–1 score per photo (by index) for its verdict Badge; nil hides it.
    var scores: [Double?]
    var format: PhotoCardFormat
    var emptyTitle: String
    var bleed: CGFloat
    /// Force the add button's icon-only state (e.g. the screen itself scrolled);
    /// nil follows the strip's own scroll.
    var collapsed: Bool?
    var onAddPhoto: (() -> Void)?
    var onSelect: (Int) -> Void

    @State private var hasScrolled = false

    private static let space = "PhotoStrip"
    /// README: "As soon as the strip scrolls (more than 8px)" = `spacing-2`.
    private static let scrollThreshold = DS.Spacing.s2

    init(
        photos: [PhotoCardSource],
        scores: [Double?] = [],
        format: PhotoCardFormat = .portrait,
        emptyTitle: String = "Add a photo",
        bleed: CGFloat = DS.Spacing.gutter,
        collapsed: Bool? = nil,
        onAddPhoto: (() -> Void)? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.photos = photos
        self.scores = scores
        self.format = format
        self.emptyTitle = emptyTitle
        self.bleed = bleed
        self.collapsed = collapsed
        self.onAddPhoto = onAddPhoto
        self.onSelect = onSelect
    }

    var body: some View {
        if photos.isEmpty {
            if let onAddPhoto {
                PhotoStripEmptyAddTile(title: emptyTitle, isLandscape: format == .landscape, action: onAddPhoto)
            } else {
                PhotoCard(.none(), size: .lg, format: format)
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
                            format: format,
                            badge: score(at: index).map { .score($0) },
                            accessibilityLabel: "Photo \(index + 1) of \(photos.count)"
                        )
                    }
                    .buttonStyle(AppPressableButtonStyle())
                }
            }
            .scrollTargetLayout()
            .onGeometryChange(for: Bool.self) { proxy in
                proxy.frame(in: .named(Self.space)).minX < bleed - Self.scrollThreshold
            } action: { scrolled in
                hasScrolled = scrolled
            }
        }
        // README "Use": the track is the system's one scroller — snap to each tile.
        .scrollTargetBehavior(.viewAligned)
        .coordinateSpace(.named(Self.space))
        .contentMargins(.horizontal, bleed, for: .scrollContent)
        .overlay(alignment: .bottomLeading) {
            if let onAddPhoto {
                PhotoStripAddButton(isCollapsed: collapsed ?? hasScrolled, action: onAddPhoto)
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
                    PhotoStrip(photos: [.none(cuisine: "thai"), .none()], format: .landscape, onSelect: { _ in })
                    PhotoStrip(photos: [], onAddPhoto: {}, onSelect: { _ in })
                    PhotoStrip(photos: [], format: .landscape, onAddPhoto: {}, onSelect: { _ in })
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
