import Foundation
import Supabase

extension FoodStore {

    struct AnalyzeHealthPayload: Encodable {
        let recipe_id: String?
        let name: String
        let ingredients: [RecipeIngredient]
        let instructions: [String]
        let serves: Int?
        let cuisine: String?
    }

    /// Evaluates the nutritional health index of a recipe using scientific ingredient and cooking technique scoring.
    @discardableResult
    func analyzeHealth(for recipe: Recipe) async throws -> HealthIndex {
        let payload = AnalyzeHealthPayload(
            recipe_id: recipe.id.uuidString,
            name: recipe.name,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            serves: recipe.serves,
            cuisine: recipe.cuisine
        )

        let result: HealthIndex = try await supabase.functions.invoke(
            "analyze-recipe-health",
            options: FunctionInvokeOptions(body: payload)
        )

        // If user owns the recipe, persist the score to the database
        if recipe.ownerID == userID {
            let updated: Recipe = try await supabase
                .from("dishes")
                .update(RecipeHealthPatch(
                    health_score: result.score,
                    health_verdict: result.verdict,
                    health_rationale: result.rationale,
                    health_breakdown: result.breakdown
                ))
                .eq("id", value: recipe.id.uuidString)
                .select()
                .single()
                .execute()
                .value

            upsertLocal(recipe: updated)
        }

        return result
    }
}
