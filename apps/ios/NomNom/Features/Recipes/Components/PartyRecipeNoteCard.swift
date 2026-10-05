import SwiftUI

/// The current party's note on a recipe (`party_recipe_notes`): what this table has
/// learned about the dish. Anyone in the party can write it here; Nom Nom Pro adds to it
/// automatically from the meal score sheet's "Make it land next time". A SectionCard
/// holding a NoteField, so the note reads as the cook's note and opens NoteEditorSheet
/// to edit. Hidden when there is no current party. RecipeDetailView loads the notes.
struct PartyRecipeNoteCard: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store

    var body: some View {
        if let party = store.currentParty {
            SectionCard("Note for \(party.name)") {
                NoteField(
                    "What should you change next time?",
                    text: Binding(
                        get: { store.partyRecipeNote(dishID: recipeID, partyID: party.id)?.body ?? "" },
                        set: { body in Task { await store.saveNote(body, dishID: recipeID, partyID: party.id) } }
                    ),
                    title: "Note for \(party.name)",
                    bulleted: true
                )
            }
        }
    }
}
