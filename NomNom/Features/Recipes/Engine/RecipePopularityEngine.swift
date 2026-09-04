import Foundation

/// Pure mathematical scoring engine to calculate recipe popularity.
///
/// Popularity balances three key signals:
/// 1. **Quality / Score**: Bayesian average of eater reactions (0.0 to 1.0).
/// 2. **Frequency**: Number of times cooked, with logarithmic scaling.
/// 3. **Calendar Time**: Exponential decay over time (90-day half-life) with a classic baseline floor.
enum RecipePopularityEngine {

    /// Prior mean score (0.60 equates to "Good")
    private static let priorScore: Double = 0.60
    /// Weight given to the prior (equivalent to 2 observations)
    private static let priorWeight: Double = 2.0
    /// Half-life in days for cooking recency decay
    private static let halfLifeDays: Double = 90.0
    /// Minimum weight floor for historical servings (retains all-time classics)
    private static let floorWeight: Double = 0.25

    /// Calculates a composite popularity score for a recipe.
    ///
    /// - Parameters:
    ///   - recipe: The recipe to score.
    ///   - servings: Historical meals where this recipe was cooked.
    ///   - mealScores: Pre-computed average score (0.0 to 1.0) for each meal ID.
    ///   - now: Reference date for recency calculation (defaults to current time).
    /// - Returns: A positive popularity score, or 0.0 if the recipe has never been cooked.
    static func popularity(
        for recipe: Recipe,
        servings: [Meal],
        mealScores: [UUID: Double],
        now: Date = .now
    ) -> Double {
        guard !servings.isEmpty else { return 0.0 }

        // 1. Quality rating with Bayesian smoothing
        var ratedCount: Double = 0
        var totalScoreSum: Double = 0

        for meal in servings {
            if let score = mealScores[meal.id] {
                ratedCount += 1
                totalScoreSum += score
            }
        }

        let bayesianScore = (priorWeight * priorScore + totalScoreSum) / (priorWeight + ratedCount)

        // 2. Frequency with calendar time decay
        var effectiveServings: Double = 0
        for meal in servings {
            let daysAgo = max(0, now.timeIntervalSince(meal.eatenOn) / 86400.0)
            let decay = pow(2.0, -daysAgo / halfLifeDays)
            let mealWeight = floorWeight + (1.0 - floorWeight) * decay
            effectiveServings += mealWeight
        }

        // 3. Composite score combining quality and log-scaled effective frequency
        return bayesianScore * log(1.0 + 1.5 * effectiveServings)
    }

    /// Sorts a collection of recipes by popularity descending.
    static func sort(
        recipes: [Recipe],
        servingsByRecipe: [UUID: [Meal]],
        mealScores: [UUID: Double],
        now: Date = .now
    ) -> [Recipe] {
        let scores = Dictionary(uniqueKeysWithValues: recipes.map { recipe in
            let servings = servingsByRecipe[recipe.id] ?? []
            let score = popularity(for: recipe, servings: servings, mealScores: mealScores, now: now)
            return (recipe.id, score)
        })

        let latestServings: [UUID: Date] = Dictionary(uniqueKeysWithValues: recipes.compactMap { recipe in
            guard let lastDate = (servingsByRecipe[recipe.id] ?? []).map(\.eatenOn).max() else { return nil }
            return (recipe.id, lastDate)
        })

        return recipes.sorted { lhs, rhs in
            let scoreL = scores[lhs.id] ?? 0
            let scoreR = scores[rhs.id] ?? 0
            if abs(scoreL - scoreR) > 0.0001 {
                return scoreL > scoreR
            }

            // Tie breaker 1: Most recently cooked
            let lastL = latestServings[lhs.id]
            let lastR = latestServings[rhs.id]
            if let lastL, let lastR, lastL != lastR {
                return lastL > lastR
            } else if lastL != nil && lastR == nil {
                return true
            } else if lastL == nil && lastR != nil {
                return false
            }

            // Tie breaker 2: Recipe creation date
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            // Tie breaker 3: Alphabetical by name
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
