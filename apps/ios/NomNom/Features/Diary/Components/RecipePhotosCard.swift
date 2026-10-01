import SwiftUI

/// The recipe's page photos (cookbook pages, documents) as PhotoCard `sm` tiles with
/// a "Page N" Badge, scrolling sideways in a SectionCard; tap opens the viewer.
struct RecipePhotosCard: View {
    let recipe: Recipe

    @State private var selectedPhotoIndex: Int?

    var body: some View {
        if !recipe.recipePhotoPaths.isEmpty {
            SectionCard("Recipe pages", trailing: pageCount) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s2_5) {
                        ForEach(Array(recipe.recipePhotoPaths.enumerated()), id: \.element) { index, path in
                            Button {
                                selectedPhotoIndex = index
                            } label: {
                                PhotoCard(
                                    .remote(path: path, bucket: SupabaseConfig.recipeBucket),
                                    size: .sm,
                                    badge: .custom(Badge("Page \(index + 1)", variant: .secondary, appearance: .elevated, size: .sm)),
                                    accessibilityLabel: "Recipe page \(index + 1)"
                                )
                            }
                            .buttonStyle(AppPressableButtonStyle())
                        }
                    }
                }
            }
            .sheet(item: Binding(
                get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
                set: { selectedPhotoIndex = $0?.index }
            )) { wrapper in
                MediaViewerSheet(
                    .paths(recipe.recipePhotoPaths, bucket: SupabaseConfig.recipeBucket),
                    startIndex: wrapper.index,
                    title: "Recipe Page"
                )
            }
        }
    }

    private var pageCount: String {
        recipe.recipePhotoPaths.count == 1 ? "1 page" : "\(recipe.recipePhotoPaths.count) pages"
    }
}
