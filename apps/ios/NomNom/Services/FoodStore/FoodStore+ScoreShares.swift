import Foundation

extension FoodStore {
    /// Each rater's part of a dish's average score (0–100 points): the average of its
    /// servings' averages, split by who gave what. The parts add up to that average.
    func scoreShares(forDish dishID: UUID, inParty partyID: UUID? = nil) -> [RaterRef: Double] {
        let meals = partyID.map { partyServings(of: dishID, partyID: $0) } ?? servings(of: dishID)
        let rated = meals.map { ratings(forMeal: $0.id) }.filter { !$0.isEmpty }
        var shares: [RaterRef: Double] = [:]
        for list in rated {
            for rating in list {
                shares[rating.source, default: 0] += rating.score * 100 / Double(list.count * rated.count)
            }
        }
        return shares
    }

    /// The meals this party has eaten of a dish.
    func partyServings(of dishID: UUID, partyID: UUID) -> [Meal] {
        let mealIDs = Set((mealPartiesByParty[partyID] ?? []).map(\.mealID))
        return servings(of: dishID).filter { mealIDs.contains($0.id) }
    }

    /// One Bar block per rater, in a stable order (name, then id) so a person keeps
    /// their `chart-series` colour (Bar README: assigned by index, never cycled).
    func barSegments(_ shares: [RaterRef: Double]) -> [BarSegment] {
        shares
            .map { (name: firstName(for: $0.key), id: $0.key.id.uuidString, value: $0.value) }
            .sorted { ($0.name, $0.id) < ($1.name, $1.id) }
            .enumerated()
            .map { BarSegment(value: $1.value, ink: .chart($0), label: $1.name) }
    }
}
