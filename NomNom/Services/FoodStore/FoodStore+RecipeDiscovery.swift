import Foundation

extension FoodStore {

    // MARK: - Discovery & Ranking Helpers

    /// Computes the composite popularity score for a recipe based on eater reactions,
    /// times cooked, and calendar time decay.
    func popularityScore(for recipe: Recipe) -> Double {
        let mealServings = servings(of: recipe.id)
        let mealScores = Dictionary(uniqueKeysWithValues: mealServings.compactMap { meal in
            averageScore(forMeal: meal.id).map { (meal.id, $0) }
        })
        return RecipePopularityEngine.popularity(
            for: recipe,
            servings: mealServings,
            mealScores: mealScores
        )
    }

    /// All recipes sorted by popularity using `RecipePopularityEngine`.
    var popularRecipes: [Recipe] {
        let allScores = Dictionary(uniqueKeysWithValues: meals.compactMap { meal in
            averageScore(forMeal: meal.id).map { (meal.id, $0) }
        })
        return RecipePopularityEngine.sort(
            recipes: recipes,
            servingsByRecipe: mealsByDish,
            mealScores: allScores
        )
    }

    /// All recipes matching a category name or cuisine, sorted by popularity.
    func recipes(inCategory categoryName: String) -> [Recipe] {
        let normalized = categoryName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matching = recipes.filter { recipe in
            if let cuisine = recipe.cuisine?.lowercased() {
                let parts = Cuisine.parseMultiple(from: cuisine).map { $0.lowercased() }
                if parts.contains(normalized) || cuisine == normalized {
                    return true
                }
            }
            return recipe.tags.contains { $0.lowercased() == normalized }
        }
        let allScores = Dictionary(uniqueKeysWithValues: meals.compactMap { meal in
            averageScore(forMeal: meal.id).map { (meal.id, $0) }
        })
        return RecipePopularityEngine.sort(
            recipes: matching,
            servingsByRecipe: mealsByDish,
            mealScores: allScores
        )
    }

    /// Number of recipes belonging to a specific category or cuisine.
    func recipeCount(forCategory categoryName: String) -> Int {
        let normalized = categoryName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return recipes.filter { recipe in
            if let cuisine = recipe.cuisine?.lowercased() {
                let parts = Cuisine.parseMultiple(from: cuisine).map { $0.lowercased() }
                if parts.contains(normalized) || cuisine == normalized {
                    return true
                }
            }
            return recipe.tags.contains { $0.lowercased() == normalized }
        }.count
    }

    /// Recipes sorted by most recently cooked date descending.
    var recentRecipes: [Recipe] {
        recipes
            .compactMap { recipe -> (Recipe, Date)? in
                guard let last = servings(of: recipe.id).map(\.eatenOn).max() else { return nil }
                return (recipe, last)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    /// Recipes that have been cooked, ranked by frequency and recency.
    /// Falls back to the user's recently created recipes if no meals have been logged yet.
    var recentAndFrequentRecipes: [Recipe] {
        let history = dishHistory
        let cooked = recipes.filter { (history[$0.id]?.timesServed ?? 0) > 0 }
        if !cooked.isEmpty {
            return cooked.sorted { lhs, rhs in
                let histL = history[lhs.id] ?? .none
                let histR = history[rhs.id] ?? .none
                let dateL = histL.lastServed ?? lhs.createdAt
                let dateR = histR.lastServed ?? rhs.createdAt
                let daysL = max(0, Date.now.timeIntervalSince(dateL) / 86400)
                let daysR = max(0, Date.now.timeIntervalSince(dateR) / 86400)
                let scoreL = Double(histL.timesServed) * 3.0 - (daysL / 14.0)
                let scoreR = Double(histR.timesServed) * 3.0 - (daysR / 14.0)
                if abs(scoreL - scoreR) > 0.01 {
                    return scoreL > scoreR
                }
                return dateL > dateR
            }
        }
        return myRecipes.sorted { $0.createdAt > $1.createdAt }
    }

    /// Recipes that were rated positively in historical meals (average score >= 0.70)
    /// or explicitly marked as household staples.
    var pastFavoriteRecipes: [Recipe] {
        recipes.filter { recipe in
            let dishMeals = servings(of: recipe.id)
            guard !dishMeals.isEmpty else { return false }
            if dishMeals.contains(where: { $0.repeatDesire == .staple }) {
                return true
            }
            let dishScores = dishMeals.compactMap { averageScore(forMeal: $0.id) }
            guard !dishScores.isEmpty else { return false }
            let avg = dishScores.reduce(0, +) / Double(dishScores.count)
            return avg >= 0.70
        }
        .sorted { lhs, rhs in
            let scoreL = averageScore(forDish: lhs.id) ?? 0
            let scoreR = averageScore(forDish: rhs.id) ?? 0
            if abs(scoreL - scoreR) > 0.01 {
                return scoreL > scoreR
            }
            let dateL = servings(of: lhs.id).compactMap(\.eatenOn).max() ?? lhs.createdAt
            let dateR = servings(of: rhs.id).compactMap(\.eatenOn).max() ?? rhs.createdAt
            return dateL > dateR
        }
    }
}
