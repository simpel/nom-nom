import Foundation

/// A new recipe's cover while it is being made: the AI photo is generated in the
/// background, and a photo the person takes or picks meanwhile stops it and wins.
extension FoodStore {

    /// Generates an AI cover for a recipe with no photo. The task belongs to the store,
    /// so closing the sheet that started it does not stop it.
    func startRecipePhotoGeneration(for recipe: Recipe) {
        guard recipePhotoTasks[recipe.id] == nil else { return }
        recipePhotoTasks[recipe.id] = Task {
            do {
                try await generateRecipeImage(for: recipe)
            } catch {
                if !Task.isCancelled {
                    Self.log.error("Failed to generate recipe image: \(error.localizedDescription, privacy: .public)")
                }
            }
            // A cancelled task was already removed, and a newer one may hold the slot.
            if !Task.isCancelled { recipePhotoTasks[recipe.id] = nil }
        }
    }

    /// Stops a running AI cover. The request is dropped; the server skips attaching
    /// its photo once the recipe has one (`generate-recipe-photo`).
    func cancelRecipePhotoGeneration(for recipeID: UUID) {
        recipePhotoTasks.removeValue(forKey: recipeID)?.cancel()
        generatingPhotoRecipeIDs.remove(recipeID)
    }

    /// Makes a photo the person took or picked the recipe's cover, ahead of any it
    /// already has, and stops the AI cover if it is still being made.
    func setRecipeCover(_ data: Data, for recipe: Recipe) async {
        cancelRecipePhotoGeneration(for: recipe.id)
        let current = self.recipe(recipe.id) ?? recipe
        let draft = PhotosDraft(
            items: [.added(id: UUID(), data: data)] + current.photoPaths.map { .existing(path: $0) }
        )
        do {
            try await applyCoverPhotos(draft, to: current)
        } catch {
            Self.log.error("Failed to set recipe cover: \(error.localizedDescription, privacy: .public)")
            errorMessage = Self.describe(error)
        }
    }
}
