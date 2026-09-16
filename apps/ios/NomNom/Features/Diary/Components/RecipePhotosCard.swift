import SwiftUI

/// Horizontal preview strip and viewer sheet for recipe document and cookbook page photos.
struct RecipePhotosCard: View {
    let recipe: Recipe

    @State private var showingFullScreenGallery = false
    @State private var selectedPhotoIndex = 0

    var body: some View {
        if !recipe.recipePhotoPaths.isEmpty {
            SectionCard("Recipe Photos", caption: "\(recipe.recipePhotoPaths.count) pages") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(recipe.recipePhotoPaths.enumerated()), id: \.element) { index, path in
                            Button {
                                selectedPhotoIndex = index
                                showingFullScreenGallery = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    RemoteMealPhoto(
                                        path: path,
                                        cornerRadius: AppRadius.photo,
                                        bucket: SupabaseConfig.recipeBucket
                                    )
                                    .frame(width: 120, height: 160)
                                    Text("Page \(index + 1)")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .sheet(isPresented: $showingFullScreenGallery) {
                MealGalleryViewerSheet(
                    paths: recipe.recipePhotoPaths,
                    initialIndex: selectedPhotoIndex,
                    bucket: SupabaseConfig.recipeBucket,
                    titlePrefix: "Recipe Page"
                )
            }
        }
    }
}
