import Foundation
import Supabase

extension FoodStore {
    struct GenerateMealImagePayload: Encodable {
        let mode = "meal"
        let meal_id: String
        let name: String
        let cuisine: String?
        let ingredients: [RecipeIngredient]
        let instructions: [String]
    }

    /// Invokes `generate-dish-photo` in meal mode: the meal's recipe plated and laid for eating
    /// (cutlery, a napkin and a drink) on the same oak table as recipe photos. The function
    /// saves it to `meal-photos` and puts it first in `meals.photo_paths`.
    @discardableResult
    func generateMealImage(for meal: Meal, recipe: Recipe) async throws -> GenerateRecipeImageResult {
        generatingPhotoMealIDs.insert(meal.id)
        defer { generatingPhotoMealIDs.remove(meal.id) }
        Self.log.info("Generating AI meal image for meal \(meal.id, privacy: .public) ('\(recipe.name, privacy: .public)')")

        let payload = GenerateMealImagePayload(
            meal_id: meal.id.uuidString,
            name: meal.title ?? recipe.name,
            cuisine: recipe.cuisine,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions
        )

        let result: GenerateRecipeImageResult = try await supabase.functions.invoke(
            "generate-dish-photo",
            options: FunctionInvokeOptions(body: payload)
        )

        if let path = result.photoPath {
            if let b64 = result.imageBase64, let data = Data(base64Encoded: b64) {
                PhotoCache.shared.put(data, for: path)
            }
            var updated = self.meal(meal.id) ?? meal
            if !updated.photoPaths.contains(path) {
                updated.photoPaths = [path] + updated.photoPaths
            }
            upsertLocal(meal: updated)
            reindex()
        }

        return result
    }
}
