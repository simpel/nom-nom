import SwiftUI

/// A titled photo editor section for meals, recipe covers, avatars and party covers:
/// a DSSection header (`title`, `caption` as trailing text) over a PhotoStripEditor
/// bound to the draft, with taps opening the MediaViewerSheet.
struct AssetPhotosPickerSection: View {
    @Binding var draft: FoodStore.PhotosDraft
    var title: String = "Photos"
    var caption: String? = "Optional"
    var bucket: String = SupabaseConfig.photoBucket
    var maxCount: Int = FoodStore.PhotosDraft.maxCount

    @State private var previewIndex: Int?

    var body: some View {
        DSSection(title, trailing: caption) {
            PhotoStripEditor(draft: $draft, bucket: bucket, maxCount: maxCount) { index in
                previewIndex = index
            }
        }
        .sheet(item: Binding(
            get: { previewIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { previewIndex = $0?.index }
        )) { item in
            MediaViewerSheet(.photosDraft(draft, bucket: bucket), startIndex: item.index)
        }
    }
}

private struct AssetPhotosPickerSectionPreview: View {
    @State private var draft = FoodStore.PhotosDraft()

    var body: some View {
        NomNomPreview(inNavigationStack: false) { _ in
            AssetPhotosPickerSection(draft: $draft, title: "Cover Photo")
                .padding(DS.Spacing.gutter)
                .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { AssetPhotosPickerSectionPreview() }
#Preview("Dark") { AssetPhotosPickerSectionPreview().preferredColorScheme(.dark) }
