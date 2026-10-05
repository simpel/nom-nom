import SwiftUI

/// The Recipes tab's Pro card for the current party. AI picks ("Picked for <party>",
/// each card captioned with the model's reason) when the party has enough history;
/// otherwise the recipes it has already agreed on ("Safe bets for <party>").
struct PartyRecommendationsCard: View {
    @Environment(FoodStore.self) private var store
    @Environment(EntitlementStore.self) private var entitlements
    let party: Party

    var body: some View {
        let picks = store.pickedRecipes(forParty: party.id)
        let reasons = Dictionary(picks.map { ($0.recipe.id, $0.reason) }, uniquingKeysWith: { first, _ in first })

        Group {
            if picks.isEmpty {
                safeBets
            } else {
                ProCard(
                    "Picked for \(party.name)",
                    sub: "\(picks.count) recipes",
                    contentBleed: DS.Spacing.s5
                ) {
                    RecipeShelf(
                        "",
                        recipes: picks.map(\.recipe),
                        category: { reasons[$0.id] },
                        bleed: DS.Spacing.s5
                    ) { RecipeDetailView(recipe: $0) }
                }
            }
        }
        .task(id: party.id) {
            // Free users see the blurred teaser only; don't spend a model call on it.
            guard entitlements.hasProAccess else { return }
            await store.refreshRecommendations(forParty: party.id)
        }
    }

    @ViewBuilder
    private var safeBets: some View {
        let safe = store.safeBetRecipes(forParty: party.id)
        ProCard(
            "Safe bets for \(party.name)",
            sub: safe.isEmpty ? nil : "\(safe.count) recipes",
            contentBleed: DS.Spacing.s5
        ) {
            RecipeShelf(
                "",
                recipes: safe,
                score: { store.partyScore(forRecipe: $0.id, partyID: party.id) },
                bleed: DS.Spacing.s5
            ) { RecipeDetailView(recipe: $0) }
        }
    }
}
