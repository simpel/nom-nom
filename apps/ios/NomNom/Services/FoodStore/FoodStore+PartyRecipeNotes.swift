import Foundation
import Supabase

/// One note per party per recipe (`party_recipe_notes`): what a table has
/// learned about a recipe. Written from the meal score sheet's tips, shown and edited on
/// the recipe.
extension FoodStore {

    private struct NoteUpsert: Encodable {
        let party_id: UUID
        let recipe_id: UUID
        let body: String
        let updated_by: UUID
    }

    func partyRecipeNote(recipeID: UUID, partyID: UUID) -> PartyRecipeNote? {
        partyRecipeNotes.first { $0.recipeID == recipeID && $0.partyID == partyID }
    }

    /// Every party's note on this recipe the user can read (RLS keeps it to their parties).
    func loadPartyRecipeNotes(recipeID: UUID) async {
        do {
            let notes: [PartyRecipeNote] = try await supabase
                .from("party_recipe_notes")
                .select()
                .eq("recipe_id", value: recipeID.uuidString)
                .execute()
                .value
            partyRecipeNotes.removeAll { $0.recipeID == recipeID }
            partyRecipeNotes.append(contentsOf: notes)
        } catch {
            Self.log.error("party_recipe_notes load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Replaces the party's note on this recipe; an empty body deletes it.
    @discardableResult
    func saveNote(_ body: String, recipeID: UUID, partyID: UUID) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmed.isEmpty {
                try await supabase
                    .from("party_recipe_notes")
                    .delete()
                    .eq("party_id", value: partyID.uuidString)
                    .eq("recipe_id", value: recipeID.uuidString)
                    .execute()
                partyRecipeNotes.removeAll { $0.recipeID == recipeID && $0.partyID == partyID }
            } else {
                let saved: PartyRecipeNote = try await supabase
                    .from("party_recipe_notes")
                    .upsert(
                        NoteUpsert(party_id: partyID, recipe_id: recipeID, body: trimmed, updated_by: userID),
                        onConflict: "party_id,recipe_id"
                    )
                    .select()
                    .single()
                    .execute()
                    .value
                partyRecipeNotes.removeAll { $0.recipeID == recipeID && $0.partyID == partyID }
                partyRecipeNotes.append(saved)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    /// Adds the tips to the party's note on this recipe, one per line, skipping lines it
    /// already has. Creates the note when there is none.
    @discardableResult
    func appendTips(_ tips: RecipeTweaks, toRecipe recipeID: UUID, party partyID: UUID) async -> Bool {
        let existing = partyRecipeNote(recipeID: recipeID, partyID: partyID)?.body ?? ""
        let have = Set(existing.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        let added = tips.noteLines.filter { !have.contains($0) }
        guard !added.isEmpty else { return true }
        let body = ([existing].filter { !$0.isEmpty } + added).joined(separator: "\n")
        return await saveNote(body, recipeID: recipeID, partyID: partyID)
    }
}
