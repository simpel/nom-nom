import Foundation

/// Personal taste-profile and health-trend aggregates for one rater, computed on-device
/// from already-loaded rating history — mirrors `FoodStore+Insights`'s party-scoped
/// aggregation, scoped to a single `RaterRef` instead.
extension FoodStore {

    func tasteProfile(for rater: RaterRef) -> RaterTasteProfile? {
        let raterRatings = ratings(for: rater)
        guard !raterRatings.isEmpty else { return nil }

        let average = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)

        var distribution: [Reaction: Int] = [:]
        for rating in raterRatings {
            distribution[rating.reaction, default: 0] += 1
        }

        var cuisineCounts: [String: Int] = [:]
        for rating in raterRatings {
            guard let meal = meal(rating.mealID), let recipe = recipe(meal.dishID),
                  let cuisine = recipe.cuisine, !cuisine.isEmpty else { continue }
            for part in Cuisine.parseMultiple(from: cuisine) {
                cuisineCounts[part, default: 0] += 1
            }
        }
        let topCuisines = cuisineCounts.sorted { $0.value > $1.value }.prefix(5)
            .map { (cuisine: $0.key, count: $0.value) }

        return RaterTasteProfile(
            averageScoreGiven: average,
            ratingDistribution: distribution,
            topCuisines: Array(topCuisines),
            totalRatingsGiven: raterRatings.count
        )
    }

    /// Reuses the party-shaped health aggregate, scoped to one person's own meals.
    func healthInsights(for rater: RaterRef) -> PartyHealthInsights? {
        healthInsights(forMeals: meals(for: rater))
    }
}
