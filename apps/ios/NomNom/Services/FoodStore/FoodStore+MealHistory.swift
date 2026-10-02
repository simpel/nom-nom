import Foundation

/// How a meal compares with the last time the same group had the dish, and how a
/// rater compares with their own usual. The one copy of the history and trend
/// logic behind Meal Detail, its score breakdown and the historical scores card.
extension FoodStore {

    /// A meal's score against the most recent earlier serving that has a score.
    struct MealScoreChange {
        /// Change in display points (0–100 scale).
        let delta: Int
        /// The earlier serving's normalised 0–1 score.
        let previousScore: Double
        let previousMeal: Meal
    }

    /// The group's name for a meal: its parties joined with " & ", else the current
    /// party, else "You".
    func partyDisplayName(forMeal meal: Meal) -> String {
        let parties = parties(forMeal: meal.id)
        if !parties.isEmpty {
            return parties.map(\.name).joined(separator: " & ")
        }
        return currentParty?.name ?? "You"
    }

    /// Earlier and later servings of this meal's dish by the same group (sharing a
    /// party; for a party-less meal, other party-less servings), newest first. The
    /// meal itself is excluded.
    func partyHistory(for meal: Meal) -> [Meal] {
        let partyIDs = Set(parties(forMeal: meal.id).map(\.id))
        return servings(of: meal.recipeID).filter { past in
            guard past.id != meal.id else { return false }
            let pastPartyIDs = Set(parties(forMeal: past.id).map(\.id))
            if partyIDs.isEmpty { return pastPartyIDs.isEmpty }
            return !pastPartyIDs.isDisjoint(with: partyIDs)
        }
        .sorted { $0.eatenOn > $1.eatenOn }
    }

    /// The meal's score vs the most recent other serving by the same group that has
    /// a score (the first scored entry of `partyHistory`, matching the old trend).
    func scoreChange(forMeal meal: Meal) -> MealScoreChange? {
        guard let current = averageScore(forMeal: meal.id) else { return nil }
        for past in partyHistory(for: meal) {
            guard let previous = averageScore(forMeal: past.id) else { continue }
            let delta = Int(((current - previous) * 100).rounded())
            return MealScoreChange(delta: delta, previousScore: previous, previousMeal: past)
        }
        return nil
    }

    /// The mean score of every scored earlier serving in `history`, 0–1.
    func averageScore(across history: [Meal]) -> Double? {
        let scores = history.compactMap { averageScore(forMeal: $0.id) }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// The party's average score over its `limit` most recent rated meals, 0–1.
    func recentAverageScore(forParty partyID: UUID, limit: Int = 20) -> Double? {
        let scores = meals(forParty: partyID)
            .sorted { ($0.eatenOn, $0.createdAt) > ($1.eatenOn, $1.createdAt) }
            .lazy
            .compactMap { self.averageScore(forMeal: $0.id) }
            .prefix(limit)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// A rater's usual score (mean of all their ratings, 0–1), leaving out one meal so
    /// a rating can be compared with it. Nil when they have no other ratings.
    func usualScore(for rater: RaterRef, excluding mealID: UUID) -> Double? {
        let scores = ratings(for: rater)
            .filter { $0.mealID != mealID }
            .map(\.reaction.score)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// A rating's change vs the rater's usual in display points, or nil when this is
    /// their first rating (or they haven't rated the meal).
    func changeVsUsual(for rater: RaterRef, on mealID: UUID) -> Int? {
        guard let rating = rating(for: rater, on: mealID),
              let usual = usualScore(for: rater, excluding: mealID) else { return nil }
        return Int(((rating.reaction.score - usual) * 100).rounded())
    }
}
