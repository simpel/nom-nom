import Foundation
import Supabase

/// Cook mode's per-step timers and ingredients: read from `dishes.instruction_details`,
/// or asked of the `analyze-recipe-steps` edge function the first time and saved back
/// (owners) or kept in memory (everyone else).
extension FoodStore {

    private struct AnalyzeStepsPayload: Encodable {
        let recipe_id: String
        let name: String
        let ingredients: [RecipeIngredient]
        let instructions: [String]
    }

    private struct AnalyzeStepsResponse: Decodable {
        let steps: [RecipeStepDetail]
    }

    private struct InstructionDetailsPatch: Encodable {
        let instruction_details: [RecipeStepDetail]
    }

    /// The recipe's step details, analysing them when missing or stale. Nil when the
    /// recipe has no steps or the analysis fails (cook mode then shows text only).
    func stepDetails(for recipe: Recipe) async -> [RecipeStepDetail]? {
        if let current = recipe.currentStepDetails { return current }
        guard !recipe.instructions.isEmpty else { return nil }

        do {
            let response: AnalyzeStepsResponse = try await supabase.functions.invoke(
                "analyze-recipe-steps",
                options: FunctionInvokeOptions(body: AnalyzeStepsPayload(
                    recipe_id: recipe.id.uuidString,
                    name: recipe.name,
                    ingredients: recipe.ingredients,
                    instructions: recipe.instructions
                ))
            )
            guard response.steps.count == recipe.instructions.count else { return nil }

            var updated = recipe
            updated.instructionDetails = response.steps
            if recipe.ownerID == userID {
                do {
                    updated = try await supabase
                        .from("dishes")
                        .update(InstructionDetailsPatch(instruction_details: response.steps))
                        .eq("id", value: recipe.id.uuidString)
                        .select()
                        .single()
                        .execute()
                        .value
                } catch {
                    Self.log.error("Could not save step details: \(error.localizedDescription, privacy: .public)")
                }
            }
            upsertLocal(recipe: updated)
            return response.steps
        } catch {
            Self.log.error("analyze-recipe-steps failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
