import Foundation

extension FoodStore {
    /// Result structure for dinner party scoring statistics.
    struct PartyScoreStats {
        let score: Double
        let count: Int
        let reaction: Reaction
    }

    /// Average rating score for a specific rater (or all raters if nil) across the last `limit`
    /// scores in a given dinner party. Time is not relevant — strictly latest N scores.
    func partyAverageScore(
        partyID: UUID,
        for raterRef: RaterRef? = nil,
        limit: Int = 20
    ) -> PartyScoreStats? {
        let partyMealIDs = Set((mealPartiesByParty[partyID] ?? []).map(\.mealID))
        guard !partyMealIDs.isEmpty else { return nil }

        var candidateRatings: [(rating: MealRating, meal: Meal)] = []
        for mealID in partyMealIDs {
            guard let meal = mealByID[mealID] else { continue }
            let ratings = ratingsByMeal[mealID] ?? []
            for r in ratings {
                if let raterRef {
                    if r.source == raterRef {
                        candidateRatings.append((r, meal))
                    }
                } else {
                    candidateRatings.append((r, meal))
                }
            }
        }

        // Sort by meal eatenOn / createdAt descending
        candidateRatings.sort { lhs, rhs in
            if lhs.meal.eatenOn != rhs.meal.eatenOn {
                return lhs.meal.eatenOn > rhs.meal.eatenOn
            }
            return lhs.meal.createdAt > rhs.meal.createdAt
        }

        let slice = candidateRatings.prefix(limit)
        guard !slice.isEmpty else { return nil }

        let scores = slice.map(\.rating.score)
        let avg = scores.reduce(0.0, +) / Double(scores.count)

        return PartyScoreStats(score: avg, count: slice.count, reaction: Reaction(score: avg))
    }
}
