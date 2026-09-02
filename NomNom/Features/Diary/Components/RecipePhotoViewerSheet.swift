import SwiftUI

/// Full-screen viewer for inspecting picked or existing recipe photos.
struct RecipePhotoViewerSheet: View {
    let draft: FoodStore.RecipeDraft
    var initialIndex: Int = 0

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int = 0

    private var totalCount: Int {
        draft.existingPhotoPaths.count + draft.addedPhotoData.count
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(Array(draft.existingPhotoPaths.enumerated()), id: \.element) { index, path in
                    RemoteMealPhoto(path: path, cornerRadius: 0, bucket: SupabaseConfig.recipeBucket)
                        .scaledToFit()
                        .tag(index)
                }

                ForEach(Array(draft.addedPhotoData.enumerated()), id: \.offset) { offset, data in
                    let absoluteIndex = draft.existingPhotoPaths.count + offset
                    MealPhoto(data: data, cornerRadius: 0)
                        .scaledToFit()
                        .tag(absoluteIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: totalCount > 1 ? .always : .never))
            .navigationTitle(totalCount > 1 ? "Recipe Page \(selection + 1) of \(totalCount)" : "Recipe Page")
            .mediaViewerStyle()
            .onAppear {
                selection = initialIndex
            }
        }
    }
}
