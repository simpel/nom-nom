import SwiftUI

/// The recipe's two scores: the household score (compact; its action opens the
/// recipe leaderboard and its caption carries the rank, replacing the old rank chip)
/// and the featured health score (compact, opens RecipeHealthRationaleSheet).
struct RecipeScoreCards: View {
    let recipe: Recipe
    let isAnalyzingHealth: Bool
    let healthAnalysisFailed: Bool
    let onOpenHealth: () -> Void
    let onOpenLeaderboard: () -> Void

    @Environment(FoodStore.self) private var store

    /// Position among the user's recipes by average score (1-based).
    private var rank: Int? {
        let ranked = store.myDishes
            .compactMap { dish in store.averageScore(forDish: dish.id).map { (dish.id, $0) } }
            .sorted { $0.1 > $1.1 }
        return ranked.firstIndex { $0.0 == recipe.id }.map { $0 + 1 }
    }

    private var ratedCount: Int {
        store.servings(of: recipe.id).filter { store.averageScore(forMeal: $0.id) != nil }.count
    }

    private var householdCount: String {
        ratedCount == 1 ? "1 meal" : "\(ratedCount) meals"
    }

    private var healthCaption: String? {
        if let healthIndex = recipe.healthIndex { return healthIndex.tier.explanation }
        if isAnalyzingHealth { return nil }
        if recipe.ingredients.isEmpty { return "Add ingredients to get a health score." }
        return healthAnalysisFailed ? "Couldn\u{2019}t score this recipe right now." : nil
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            ScoreCard(
                score: store.averageScore(forDish: recipe.id),
                layout: .compact,
                title: "Household score",
                count: householdCount,
                caption: rank.map { "Ranked \($0.ordinalString) of your recipes" },
                action: onOpenLeaderboard
            )

            ScoreCard(
                score: recipe.healthIndex.map { Double($0.score) / 100 },
                verdict: recipe.healthIndex?.verdict,
                layout: .compact,
                featured: true,
                title: "Health score",
                systemImage: "leaf",
                caption: healthCaption,
                isLoading: isAnalyzingHealth,
                action: recipe.healthIndex == nil ? nil : onOpenHealth
            )
        }
    }
}
