import SwiftUI
import Supabase

// Loading, toolbar and owner actions for RecipeDetailView.
extension RecipeDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if showCloseButton {
            ToolbarItem(placement: .topBarLeading) {
                SheetCloseButton { dismiss() }
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if let recipe {
                let isFavorite = store.isFavorite(recipe: recipe)
                Button {
                    Task { await store.toggleFavorite(recipe: recipe) }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? DS.Color.primary : DS.Color.textSecondary)
                }
                .accessibilityLabel(isFavorite ? "Remove from Favourites" : "Add to Favourites")
            }

            if let recipe, recipe.ownerID == store.userID {
                Menu {
                    if recipe.photoPaths.isEmpty {
                        Button {
                            generatePhoto(for: recipe)
                        } label: {
                            Label(isGeneratingPhoto ? "Generating Photo…" : "Generate Photo with AI", systemImage: "sparkles")
                        }
                        .disabled(isGeneratingPhoto)
                    }
                    Button { showEditSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { confirmDeleteRecipe = true } label: {
                        Label("Delete recipe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis").fontWeight(.semibold)
                }
                .accessibilityLabel("Recipe options")
            }
        }
    }

    /// Fetches a recipe that isn't in the store yet, then backfills its health score
    /// (recipes saved before scoring existed, or whose first analysis failed). Silent:
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

        guard let recipe, recipe.healthIndex == nil, !recipe.ingredients.isEmpty, !healthAnalysisFailed else { return }
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

    func generatePhoto(for recipe: Recipe) {
        guard !isGeneratingPhoto else { return }
        isGeneratingPhoto = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            defer { isGeneratingPhoto = false }
            do {
                try await store.generateRecipeImage(for: recipe)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
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
