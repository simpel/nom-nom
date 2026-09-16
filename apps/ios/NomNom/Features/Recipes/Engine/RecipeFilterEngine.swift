import Foundation

/// Engine for applying sort and filter criteria to a collection of recipes.
@MainActor
enum RecipeFilterEngine {

    static func apply(
        criteria: RecipeFilterCriteria,
        to recipes: [Recipe],
        store: FoodStore
    ) -> [Recipe] {
        var result = recipes

        // 1. Effort Filter
        if let targetEffort = criteria.effort {
            result = result.filter { $0.effort == targetEffort }
        }

        // 2. Score Filter
        if let minScore = criteria.scoreThreshold.minScore {
            result = result.filter { recipe in
                let servings = store.servings(of: recipe.id)
                let scores = servings.compactMap { store.averageScore(forMeal: $0.id) }
                guard !scores.isEmpty else { return false }
                let avg = scores.reduce(0, +) / Double(scores.count)
                return avg >= minScore
            }
        }

        // 3. Favourites Only Filter
        if criteria.onlyFavorites {
            result = result.filter { store.isFavorite(recipe: $0) }
        }

        // 4. Sort Order
        let sorted: [Recipe]
        switch criteria.sort {
        case .popular:
            let allScores = Dictionary(uniqueKeysWithValues: store.meals.compactMap { meal in
                store.averageScore(forMeal: meal.id).map { (meal.id, $0) }
            })
            sorted = RecipePopularityEngine.sort(
                recipes: result,
                servingsByRecipe: store.mealsByDish,
                mealScores: allScores
            )

        case .effort:
            sorted = result.sorted { lhs, rhs in
                let lEffort = lhs.effort?.rawValue ?? 99
                let rEffort = rhs.effort?.rawValue ?? 99
                if lEffort != rEffort {
                    return lEffort < rEffort
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

        case .recent:
            sorted = result.sorted { lhs, rhs in
                let lDate = store.servings(of: lhs.id).map(\.eatenOn).max()
                let rDate = store.servings(of: rhs.id).map(\.eatenOn).max()
                if let lDate, let rDate, lDate != rDate {
                    return lDate > rDate
                } else if lDate != nil && rDate == nil {
                    return true
                } else if lDate == nil && rDate != nil {
                    return false
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

        case .alphabetical:
            sorted = result.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        }

        // 5. Favourites on top (preserving secondary sort order)
        let favorites = sorted.filter { store.isFavorite(recipe: $0) }
        let nonFavorites = sorted.filter { !store.isFavorite(recipe: $0) }
        return favorites + nonFavorites
    }
}
