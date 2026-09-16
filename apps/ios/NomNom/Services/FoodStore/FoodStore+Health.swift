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
        print("[HEALTH_DEBUG] ==================================================")
        print("[HEALTH_DEBUG] FoodStore.analyzeHealth starting for recipe: '\(recipe.name)' (ID: \(recipe.id), owner: \(recipe.ownerID), user: \(self.userID))")
        print("[HEALTH_DEBUG] Ingredients count: \(recipe.ingredients.count), Instructions count: \(recipe.instructions.count)")
        Self.log.info("Analyzing health for recipe '\(recipe.name, privacy: .public)' (id: \(recipe.id, privacy: .public), owner: \(recipe.ownerID, privacy: .public), current user: \(self.userID, privacy: .public))")

        let payload = AnalyzeHealthPayload(
            recipe_id: recipe.id.uuidString,
            name: recipe.name,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            serves: recipe.serves,
            cuisine: recipe.cuisine
        )

        let result: HealthIndex
        do {
            print("[HEALTH_DEBUG] Invoking Supabase edge function 'analyze-recipe-health'...")
            result = try await supabase.functions.invoke(
                "analyze-recipe-health",
                options: FunctionInvokeOptions(body: payload)
            )
            print("[HEALTH_DEBUG] Edge Function returned SUCCESS: score=\(result.score), verdict='\(result.verdict)', rationale='\(result.rationale)'")
            if let breakdown = result.breakdown {
                print("[HEALTH_DEBUG] Breakdown: positives=\(breakdown.positives), cookingImpact='\(breakdown.cookingImpact ?? "none")', macros=\(String(describing: breakdown.macros))")
            } else {
                print("[HEALTH_DEBUG] Breakdown is nil")
            }
            Self.log.info("Successfully received health index from Edge Function: score=\(result.score), verdict=\(result.verdict, privacy: .public), rationale=\(result.rationale, privacy: .public)")
        } catch {
            print("[HEALTH_DEBUG] ERROR invoking analyze-recipe-health edge function: \(error)")
            Self.log.error("Failed to invoke analyze-recipe-health edge function: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Persist to database if owned by current user
        if recipe.ownerID == userID {
            do {
                print("[HEALTH_DEBUG] Persisting health score to database for owned recipe \(recipe.id)...")
                let updated: Recipe = try await supabase
                    .from("dishes")
                    .update(RecipeHealthPatch(
                        health_score: result.score,
                        health_verdict: result.verdict,
                        health_rationale: result.rationale,
                        health_breakdown: result.breakdown,
                        canonical_ingredients: result.canonicalIngredients
                    ))
                    .eq("id", value: recipe.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value

                upsertLocal(recipe: updated)
                print("[HEALTH_DEBUG] Successfully persisted health score to database and updated local store for recipe \(recipe.id)")
                Self.log.info("Persisted health score to database for recipe \(recipe.id, privacy: .public)")
            } catch {
                print("[HEALTH_DEBUG] Could not persist to database: \(error). Updating in-memory recipe.")
                Self.log.error("Could not persist health score to database: \(error.localizedDescription, privacy: .public). Updating in-memory recipe.")
                var localCopy = recipe
                localCopy.healthScore = result.score
                localCopy.healthVerdict = result.verdict
                localCopy.healthRationale = result.rationale
                localCopy.healthBreakdown = result.breakdown
                localCopy.canonicalIngredients = result.canonicalIngredients
                upsertLocal(recipe: localCopy)
            }
        } else {
            // Update local in-memory store so user can view it immediately
            print("[HEALTH_DEBUG] Non-owned recipe. Updating in-memory store copy directly.")
            var localCopy = recipe
            localCopy.healthScore = result.score
            localCopy.healthVerdict = result.verdict
            localCopy.healthRationale = result.rationale
            localCopy.healthBreakdown = result.breakdown
            localCopy.canonicalIngredients = result.canonicalIngredients
            upsertLocal(recipe: localCopy)
            Self.log.info("Updated in-memory health score for non-owned recipe \(recipe.id, privacy: .public)")
        }

        print("[HEALTH_DEBUG] FoodStore.analyzeHealth complete. Returned score: \(result.score)")
        print("[HEALTH_DEBUG] ==================================================")
        return result
    }
}
