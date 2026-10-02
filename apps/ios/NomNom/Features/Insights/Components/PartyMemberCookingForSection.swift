import SwiftUI

/// The member sheet's Pro block, "Cooking for Anna": the AI tip for their next dinner
/// (EditorialTextView) and a RecipeShelf of recipes they will love, bleeding to the
/// card's edges.
struct PartyMemberCookingForSection: View {
    let memberRef: RaterRef
    let name: String
    let partyID: UUID

    @Environment(FoodStore.self) private var store

    var body: some View {
        let tip = store.nextDinnerTipSegments(for: memberRef, partyID: partyID)
        let recipes = store.memberPartyRecommendations(for: memberRef, partyID: partyID).map(\.recipe)

        if !tip.isEmpty || !recipes.isEmpty {
            ProSection(
                "Cooking for \(name)",
                teaser: "See what \(name) rates highest, a tip for your next dinner, and recipes they will love.",
                contentBleed: DS.Spacing.s5
            ) {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    if !tip.isEmpty {
                        EditorialTextView(segments: tip)
                            .padding(.horizontal, DS.Spacing.s5)
                    }
                    RecipeShelf("Recipes \(name) will love", recipes: recipes, bleed: DS.Spacing.s5) {
                        RecipeDetailView(recipe: $0)
                    }
                    .padding(.horizontal, DS.Spacing.s5)
                }
            }
        }
    }
}
