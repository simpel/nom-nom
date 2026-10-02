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

        ToolbarItem(placement: .topBarTrailing) {
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
                if recipe.photoPaths.isEmpty {
                    Button(isGeneratingPhoto ? "Generating photo\u{2026}" : "Generate photo", systemImage: "sparkles") {
                        generatePhoto(for: recipe)
                    }
                    .disabled(isGeneratingPhoto)
                }
                Button("Edit recipe", systemImage: "pencil") { showEditSheet = true }
                Button("Delete recipe", systemImage: "trash", role: .destructive) { confirmDeleteRecipe = true }
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
