import SwiftUI

/// Full-screen swipeable viewer sheet for draft photos.
struct MealPhotoViewerSheet: View {
    let draft: FoodStore.PhotosDraft
    var initialIndex: Int = 0
    var bucket: String = SupabaseConfig.photoBucket

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(Array(draft.items.enumerated()), id: \.element.id) { index, item in
                    Group {
                        switch item {
                        case .existing(let path):
                            RemoteMealPhoto(path: path, cornerRadius: 0, bucket: bucket)
                        case .added(_, let data):
                            MealPhoto(data: data, cornerRadius: 0)
                        }
                    }
                    .scaledToFit()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: draft.count > 1 ? .always : .never))
            .navigationTitle(draft.count > 1 ? "Photo \(selection + 1) of \(draft.count)" : "Photo")
            .mediaViewerStyle()
            .onAppear {
                selection = initialIndex
            }
        }
    }
}
