import SwiftUI

/// The pages captured for a recipe scan: a PhotoStripEditor (remove only, page
/// badges) under a "Captured pages" header with the count. Tap a page to view it.
struct RecipeScannerStagingTray: View {
    let photos: [Data]
    let maxPhotos: Int
    var onRemove: (Int) -> Void

    @State private var previewIndex: Int?

    var body: some View {
        DSSection("Captured Pages", trailing: "\(photos.count) of \(maxPhotos)") {
            PhotoStripEditor(photos: photos, maxCount: maxPhotos, onRemove: onRemove) { index in
                previewIndex = index
            }
        }
        .sheet(item: Binding(
            get: { previewIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { previewIndex = $0?.index }
        )) { item in
            MediaViewerSheet(
                .photosDraft(FoodStore.PhotosDraft(addedData: photos)),
                startIndex: item.index,
                title: "Page"
            )
        }
    }
}
