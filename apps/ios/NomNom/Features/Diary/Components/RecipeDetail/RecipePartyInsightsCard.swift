import SwiftUI

/// The current dinner party's insights on this recipe, a Pro feature: a ProScoreCard with
/// the party's score for the dish. With Pro it opens `RecipePartyInsightsSheet`; without
/// it shows the score and an unlock button only. Hidden until the party has eaten the recipe.
struct RecipePartyInsightsCard: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store
    @State private var showInsights = false

    var body: some View {
        if let party = store.currentParty {
            let meals = store.partyServings(of: recipe.id, partyID: party.id)
            if !meals.isEmpty {
                let score = store.averageScore(across: meals)
                ProScoreCard(
                    "\(party.name) insights",
                    score: score,
                    barSegments: store.barSegments(store.scoreShares(forDish: recipe.id, inParty: party.id)),
                    action: { showInsights = true }
                )
                .sheet(isPresented: $showInsights) {
                    RecipePartyInsightsSheet(recipe: recipe, party: party)
                }
            }
        }
    }
}
