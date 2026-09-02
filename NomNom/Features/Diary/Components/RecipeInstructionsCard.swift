import SwiftUI

/// Reusable card for displaying written recipe instructions or photo pages.
struct RecipeInstructionsCard: View {
    let recipe: Recipe

    @State private var showingFullScreenGallery = false
    @State private var selectedPhotoIndex = 0
    @State private var copiedToClipboard = false

    var body: some View {
        if recipe.hasInstructions {
            SectionCard(title: "Instructions & Ingredients") {
                VStack(alignment: .leading, spacing: 12) {
                    if !recipe.recipeText.isEmpty {
                        copyButton
                    }

                    if !recipe.recipeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        textContent
                    }
                    if !recipe.recipePhotoPaths.isEmpty {
                        photosContent
                    }
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

    // MARK: - Subviews

    private var copyButton: some View {
        HStack {
            Spacer()
            Button {
                UIPasteboard.general.string = recipe.recipeText
                copiedToClipboard = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    copiedToClipboard = false
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                    Text(copiedToClipboard ? "Copied" : "Copy")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(copiedToClipboard ? .green : .accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var textContent: some View {
        Text(recipe.recipeText)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var photosContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(recipe.recipePhotoPaths.enumerated()), id: \.element) { index, path in
                    Button {
                        selectedPhotoIndex = index
                        showingFullScreenGallery = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            RemoteMealPhoto(path: path, cornerRadius: AppRadius.photo, bucket: SupabaseConfig.recipeBucket)
                                .frame(width: 120, height: 160)
                            Text("Page \(index + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
