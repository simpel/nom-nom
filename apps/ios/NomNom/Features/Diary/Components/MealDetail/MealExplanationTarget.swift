import Foundation

/// Why one rater scored a meal the way they did: what MealRaterExplanationSheet shows.
/// Shared by Meal Detail's RatingList and MealScoreBreakdownSheet.
struct MealExplanationTarget: Identifiable {
    let id = UUID()
    let raterName: String
    let affinities: [RaterTagAffinity]
    /// Their score for this meal, 0–1.
    var score: Double?
    /// Their usual score without this meal, 0–1.
    var usualScore: Double?
    /// How many ratings they have given in all.
    var ratingCount: Int = 0

    /// Nil when there is nothing to explain (no notable affinities).
    @MainActor
    init?(rater: RaterRef, name: String, meal: Meal, store: FoodStore) {
        let affinities = store.raterExplanation(for: rater, meal: meal)
        guard !affinities.isEmpty else { return nil }
        self.raterName = name
        self.affinities = affinities
        self.score = store.rating(for: rater, on: meal.id)?.reaction.score
        self.usualScore = store.usualScore(for: rater, excluding: meal.id)
        self.ratingCount = store.ratings(for: rater).count
    }
}
