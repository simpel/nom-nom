import SwiftUI
import Supabase

// Loading, toolbar and owner actions for RecipeDetailView.
extension RecipeDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if showCloseButton {
            SheetLeadingCloseItem(accessibilityLabel: "Close") { dismiss() }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if let recipe {
                let isFavorite = store.isFavorite(recipe: recipe)
                // A system bar button like the toolbar's other glyphs; filled once a favourite.
                Button {
                    Task { await store.toggleFavorite(recipe: recipe) }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart").fontWeight(.semibold)
                }
                .accessibilityLabel(isFavorite ? "Remove from Favourites" : "Add to Favourites")
                .barItemStyle()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if let recipe {
                if let shareImage {
                    ShareLink(item: recipe.shareURL, subject: Text(recipe.name), preview: SharePreview(recipe.name, image: shareImage)) {
                        Image(systemName: "square.and.arrow.up").fontWeight(.semibold)
                    }
                    .accessibilityLabel("Share recipe")
                    .barItemStyle()
                } else {
                    ShareLink(item: recipe.shareURL, subject: Text(recipe.name), preview: SharePreview(recipe.name)) {
                        Image(systemName: "square.and.arrow.up").fontWeight(.semibold)
                    }
                    .accessibilityLabel("Share recipe")
                    .barItemStyle()
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            PageMenu { recipeMenu }
        }
    }

    /// The page menu's recipe group: Generate photo, Edit and Delete for the owner.
    @ViewBuilder
    var recipeMenu: some View {
        if let recipe, recipe.ownerID == store.userID {
            Section {
                Button("Edit recipe", systemImage: "pencil") { showEditSheet = true }
                Button("Delete recipe", systemImage: "trash", role: .destructive) { confirmDeleteRecipe = true }
            }
        }
    }

    /// Fetches a recipe that isn't in the store yet, then backfills its health score
    /// (recipes saved before scoring existed, or whose first analysis failed). Pro only,
    /// since the health score is a Pro feature. Silent:
    /// there is no "generate" button.
    func loadRecipeAndHealth() async {
        if recipe == nil {
            isLoadingRemote = true
            defer { isLoadingRemote = false }
            do {
                let fetched: Recipe = try await supabase
                    .from("dishes")
                    .select()
                    .eq("id", value: recipeID.uuidString)
                    .single()
                    .execute()
                    .value
                store.upsertLocal(recipe: fetched)
                fallbackRecipe = fetched
            } catch {
                // Recipe not found or was deleted.
            }
        } else if let fallbackRecipe, store.recipe(recipeID) == nil {
            store.upsertLocal(recipe: fallbackRecipe)
        }

        if let recipe, recipe.photoPaths.isEmpty, recipe.ownerID == store.userID, !store.generatingPhotoRecipeIDs.contains(recipe.id) {
            generatePhoto(for: recipe)
        }

        if entitlements.hasProAccess, let recipe, recipe.healthIndex == nil, !recipe.ingredients.isEmpty, !healthAnalysisFailed {
            isAnalyzingHealth = true
            do {
                // Let the loading placeholder render before a request that may fail instantly.
                try await Task.sleep(for: .milliseconds(250))
                try await store.analyzeHealth(for: recipe)
            } catch {
                healthAnalysisFailed = true
            }
            isAnalyzingHealth = false
        }

        if let photoPath = self.recipe?.photoPaths.first ?? self.recipe?.recipePhotoPaths.first {
            if let data = await PhotoCache.shared.data(for: photoPath, bucket: SupabaseConfig.recipeBucket),
               let uiImage = UIImage(data: data) {
                shareImage = Image(uiImage: uiImage)
            }
        }
    }

    func generatePhoto(for recipe: Recipe) {
        Task {
            do {
                try await store.generateRecipeImage(for: recipe)
            } catch {
                FoodStore.log.error("Failed to generate recipe image: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func deleteRecipe() {
        guard let recipe else { return }
        Task {
            await store.delete(recipe: recipe)
            if store.errorMessage == nil {
                dismiss()
            } else {
                deleteError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}
