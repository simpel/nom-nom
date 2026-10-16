import SwiftUI

/// The recipe's two Pro scores: the dinner party's insights (a RecipePartyInsightsCard,
/// once the party has eaten the recipe) and the health score (a ProScoreCard: with Pro it
/// opens RecipeHealthRationaleSheet).
///
/// Without Pro, two scores are ONE pitch ProCard that sells Pro (no scores, no preview), not two
/// cards with a button each.
struct RecipeScoreCards: View {
    let recipe: Recipe
    let isAnalyzingHealth: Bool
    let healthAnalysisFailed: Bool
    let onOpenHealth: () -> Void

    @Environment(FoodStore.self) private var store
    @Environment(EntitlementStore.self) private var entitlements

    var body: some View {
        if !entitlements.hasProAccess, partyWithInsights != nil {
            ProCard(
                "Get more from every meal",
                teaser: "Dinner party insights, health scores and more come with Nom Nom Pro."
            )
        } else {
            VStack(spacing: DS.Spacing.s3) {
                RecipePartyInsightsCard(recipe: recipe)
                healthCard
            }
        }
    }

    private var healthCard: some View {
        ProScoreCard(
            "Health score",
            score: recipe.healthIndex.map { Double($0.score) / 100 },
            verdict: recipe.healthIndex?.verdict,
            isLoading: isAnalyzingHealth,
            action: recipe.healthIndex == nil ? nil : onOpenHealth
        )
    }

    private var partyWithInsights: Party? {
        guard let party = store.currentParty,
              !store.partyServings(of: recipe.id, partyID: party.id).isEmpty else { return nil }
        return party
    }
}
