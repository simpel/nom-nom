// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The one full-screen photo viewer: a paged TabView over stored photos or a
/// draft, titled "Photo 2 of 5" (just the title for a single photo), in the dark
/// `.mediaViewerStyle()` chrome with the leading close.
///
/// ```swift
/// MediaViewerSheet(.paths(meal.photoPaths), startIndex: index)
/// MediaViewerSheet(.paths(recipe.recipePhotoPaths, bucket: SupabaseConfig.recipeBucket), startIndex: index, title: "Recipe page")
/// MediaViewerSheet(.photosDraft(draft, bucket: bucket), startIndex: index)
/// ```
struct MediaViewerSheet: View {
    let source: MediaViewerSource
    var startIndex: Int
    var title: String

    @State private var selection: Int

    init(_ source: MediaViewerSource, startIndex: Int = 0, title: String = "Photo") {
        self.source = source
        self.title = title
        let count = source.pages.count
        let clamped = count == 0 ? 0 : min(max(startIndex, 0), count - 1)
        self.startIndex = clamped
        self._selection = State(initialValue: clamped)
    }

    private var pages: [MediaViewerPageSource] { source.pages }

    private var navigationTitle: String {
        pages.count > 1 ? "\(title) \(selection + 1) of \(pages.count)" : title
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    MediaViewerPage(source: page).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .always : .never))
            .navigationTitle(navigationTitle)
            .mediaViewerStyle()
        }
    }
}

private struct MediaViewerSheetPreview: View {
    var body: some View {
        let samples = ["fork.knife", "takeoutbag.and.cup.and.straw"].compactMap {
            UIImage(systemName: $0)?.withTintColor(.white).pngData()
        }
        MediaViewerSheet(.photosDraft(FoodStore.PhotosDraft(addedData: samples)), startIndex: 1)
    }
}

#Preview("Light") { MediaViewerSheetPreview() }
#Preview("Dark") { MediaViewerSheetPreview().preferredColorScheme(.dark) }
