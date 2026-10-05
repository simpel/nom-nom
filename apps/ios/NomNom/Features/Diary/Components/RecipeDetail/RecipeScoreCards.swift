import SwiftUI

/// The recipe's two Pro scores: the dinner party's insights (a RecipePartyInsightsCard,
/// once the party has eaten the recipe) and the health score (a ProScoreCard: with Pro it
/// opens RecipeHealthRationaleSheet, without it shows the score and an unlock button only).
struct RecipeScoreCards: View {
    let recipe: Recipe
    let isAnalyzingHealth: Bool
    let healthAnalysisFailed: Bool
    let onOpenHealth: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            RecipePartyInsightsCard(recipe: recipe)

            ProScoreCard(
                "Health score",
                score: recipe.healthIndex.map { Double($0.score) / 100 },
                verdict: recipe.healthIndex?.verdict,
                isLoading: isAnalyzingHealth,
                action: recipe.healthIndex == nil ? nil : onOpenHealth
            )
        }
    }
}
