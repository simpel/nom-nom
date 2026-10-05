import Foundation
import Supabase

/// One note per party per recipe (`party_recipe_notes`): what a table has
/// learned about a dish. Written from the meal score sheet's tips, shown and edited on
/// the recipe.
extension FoodStore {

    private struct NoteUpsert: Encodable {
        let party_id: UUID
        let dish_id: UUID
        let body: String
        let updated_by: UUID
    }

    func partyRecipeNote(dishID: UUID, partyID: UUID) -> PartyRecipeNote? {
        partyRecipeNotes.first { $0.dishID == dishID && $0.partyID == partyID }
    }

    /// Every party's note on this recipe the user can read (RLS keeps it to their parties).
    func loadPartyRecipeNotes(dishID: UUID) async {
        do {
            let notes: [PartyRecipeNote] = try await supabase
                .from("party_recipe_notes")
                .select()
                .eq("dish_id", value: dishID.uuidString)
                .execute()
                .value
            partyRecipeNotes.removeAll { $0.dishID == dishID }
            partyRecipeNotes.append(contentsOf: notes)
        } catch {
            Self.log.error("party_recipe_notes load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Replaces the party's note on this recipe; an empty body deletes it.
    @discardableResult
    func saveNote(_ body: String, dishID: UUID, partyID: UUID) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmed.isEmpty {
                try await supabase
                    .from("party_recipe_notes")
                    .delete()
                    .eq("party_id", value: partyID.uuidString)
                    .eq("dish_id", value: dishID.uuidString)
                    .execute()
                partyRecipeNotes.removeAll { $0.dishID == dishID && $0.partyID == partyID }
            } else {
                let saved: PartyRecipeNote = try await supabase
                    .from("party_recipe_notes")
                    .upsert(
                        NoteUpsert(party_id: partyID, dish_id: dishID, body: trimmed, updated_by: userID),
                        onConflict: "party_id,dish_id"
                    )
                    .select()
                    .single()
                    .execute()
                    .value
                partyRecipeNotes.removeAll { $0.dishID == dishID && $0.partyID == partyID }
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
    func appendTips(_ tips: RecipeTweaks, toDish dishID: UUID, party partyID: UUID) async -> Bool {
        let existing = partyRecipeNote(dishID: dishID, partyID: partyID)?.body ?? ""
        let have = Set(existing.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        let added = tips.noteLines.filter { !have.contains($0) }
        guard !added.isEmpty else { return true }
        let body = ([existing].filter { !$0.isEmpty } + added).joined(separator: "\n")
        return await saveNote(body, dishID: dishID, partyID: partyID)
    }
}
