import Foundation

extension FoodStore {

    /// "Safe bets for Fridays" on the Recipes tab: recipes the party has had at least
    /// twice, best average score first.
    func safeBetRecipes(forParty partyID: UUID, minimumServings: Int = 2, limit: Int = 10) -> [Recipe] {
        let byRecipe = Dictionary(grouping: meals(forParty: partyID), by: \.recipeID)
        return byRecipe
            .compactMap { recipeID, servings -> (Recipe, Double)? in
                guard servings.count >= minimumServings, let recipe = recipe(recipeID) else { return nil }
                let scores = servings.compactMap { averageScore(forMeal: $0.id) }
                guard !scores.isEmpty else { return nil }
                return (recipe, scores.reduce(0, +) / Double(scores.count))
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    /// The party's average score for a recipe across every time it had it.
    func partyScore(forRecipe recipeID: UUID, partyID: UUID) -> Double? {
        let scores = meals(forParty: partyID)
            .filter { $0.recipeID == recipeID }
            .compactMap { averageScore(forMeal: $0.id) }
        return scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count)
    }
}
