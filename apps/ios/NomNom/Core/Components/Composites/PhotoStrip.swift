import SwiftUI

/// The photos on a detail screen (components/PhotoStrip/README.md): equal PhotoCard `lg`
/// tiles in one `format`, `s2_5` apart, scrolling sideways and bleeding past the gutter
/// (the first tile lines up with it). With `onAddPhoto`, the strip always ends with an
/// Add photo tile the same size as a photo.
///
/// Format is a property of the strip, not of a photo: every tile gets the same one
/// (`portrait` 216×288 by default, `square` 288×288, `landscape` 288×216).
///
/// Place it inside the screen's gutter padding; `bleed` (default the gutter) is how far
/// it reaches past that padding on each side. Omit `onAddPhoto` for read-only.
///
/// - Empty, can add: the add tile alone, labelled `emptyTitle`.
/// - Empty, read-only: a PhotoCard `lg` no-photo tile.
struct PhotoStrip: View {
    let photos: [PhotoCardSource]
    /// Normalised 0–1 score per photo (by index) for its verdict Badge; nil hides it.
    var scores: [Double?]
    var format: PhotoCardFormat
    var emptyTitle: String
    var bleed: CGFloat
    var onAddPhoto: (() -> Void)?
    var onSelect: (Int) -> Void

    init(
        photos: [PhotoCardSource],
        scores: [Double?] = [],
        format: PhotoCardFormat = .portrait,
        emptyTitle: String = "Add a photo",
        bleed: CGFloat = DS.Spacing.gutter,
        onAddPhoto: (() -> Void)? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.photos = photos
        self.scores = scores
        self.format = format
        self.emptyTitle = emptyTitle
        self.bleed = bleed
        self.onAddPhoto = onAddPhoto
        self.onSelect = onSelect
    }

    var body: some View {
        if photos.isEmpty && onAddPhoto == nil {
            PhotoCard(.none(), size: .lg, format: format)
        } else {
            strip
        }
    }

    private var strip: some View {
        // README "Use": the bar is "absent on touch, where the platform draws its own.
        // Never hide the scrollbar outright" — so the system indicator stays on.
        ScrollView(.horizontal) {
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
                if let onAddPhoto {
                    PhotoStripAddTile(
                        title: photos.isEmpty ? emptyTitle : "Add photo",
                        format: format,
                        action: onAddPhoto
                    )
                }
            }
            .scrollTargetLayout()
        }
        // README "Use": the track is the system's one scroller — snap to each tile.
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, bleed, for: .scrollContent)
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
