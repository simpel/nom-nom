import Foundation
import Supabase

extension FoodStore {

    func toggleFavorite(recipe: Recipe) async {
        if isFavorite(recipe: recipe) {
            await unfavoriteRecipe(recipe)
        } else {
            await favoriteRecipe(recipe)
        }
    }

    func favoriteRecipe(_ recipe: Recipe) async {
        guard !isFavorite(recipe: recipe) else { return }

        // Optimistic local update
        let optimisticFavorite = RecipeFavorite(
            recipeID: recipe.id,
            userID: userID
        )
        recipeFavorites.append(optimisticFavorite)
        reindex()

        do {
            let created: RecipeFavorite = try await supabase
                .from("recipe_favorites")
                .insert(NewRecipeFavorite(recipe_id: recipe.id, user_id: userID))
                .select()
                .single()
                .execute()
                .value

            if let idx = recipeFavorites.firstIndex(where: { $0.id == optimisticFavorite.id }) {
                recipeFavorites[idx] = created
            }
            reindex()
            errorMessage = nil
        } catch {
            // Rollback optimistic update
            recipeFavorites.removeAll { $0.id == optimisticFavorite.id }
            reindex()
            errorMessage = Self.describe(error)
        }
    }

    func unfavoriteRecipe(_ recipe: Recipe) async {
        guard isFavorite(recipe: recipe) else { return }

        // Optimistic local update
        let removed = recipeFavorites.filter { $0.recipeID == recipe.id && $0.userID == userID }
        recipeFavorites.removeAll { $0.recipeID == recipe.id && $0.userID == userID }
        reindex()

        do {
            try await supabase
                .from("recipe_favorites")
                .delete()
                .eq("recipe_id", value: recipe.id.uuidString)
                .eq("user_id", value: userID.uuidString)
                .execute()

            errorMessage = nil
        } catch {
            // Rollback optimistic update
            recipeFavorites.append(contentsOf: removed)
            reindex()
            errorMessage = Self.describe(error)
        }
    }
}
