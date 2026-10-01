import Foundation

/// On-device, deterministic "why did they score it that way" analysis. No LLM call —
/// evaluates deviations from the rater's own baseline across normalized dish kinds,
/// ingredients, cuisines, and overall scoring patterns.
extension FoodStore {

    private var minAffinitySampleSize: Int { 2 }
    private var minAffinityDelta: Double { 0.15 } // ~one Reaction step on the 0...1 scale

    /// Every meal this rater has a verdict for (their own eating history, not meals they
    /// merely cooked for others without rating).
    func meals(for rater: RaterRef) -> [Meal] {
        var mealSet: [UUID: Meal] = [:]
        for rating in ratings(for: rater) {
            if let meal = meal(rating.mealID) {
                mealSet[meal.id] = meal
            }
        }
        return Array(mealSet.values).sorted { $0.eatenOn > $1.eatenOn }
    }

    /// Dish kind affinities where this rater's scores notably deviate from their own average.
    func dishKindAffinities(for rater: RaterRef) -> [RaterTagAffinity] {
        let raterRatings = ratings(for: rater)
        guard raterRatings.count >= minAffinitySampleSize else { return [] }

        let overallAverage = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)

        var scoresByKindID: [UUID: [Double]] = [:]
        for rating in raterRatings {
            guard let meal = meal(rating.mealID),
                  let recipe = recipe(meal.dishID),
                  let kindID = recipe.dishKindID else { continue }
            scoresByKindID[kindID, default: []].append(rating.reaction.score)
        }

        return scoresByKindID.compactMap { kindID, scores in
            guard scores.count >= minAffinitySampleSize else { return nil }
            let average = scores.reduce(0, +) / Double(scores.count)
            guard abs(average - overallAverage) >= minAffinityDelta else { return nil }
            let name = taxonomyTerms[kindID]?.name ?? "this dish kind"
            let slug = taxonomyTerms[kindID]?.slug ?? kindID.uuidString
            return RaterTagAffinity(
                kind: .dishKind(name: name),
                tag: slug,
                raterAverage: average,
                raterOverallAverage: overallAverage,
                sampleCount: scores.count
            )
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    /// Cooking method affinities where this rater's scores notably deviate from their own average.
    func cookingMethodAffinities(for rater: RaterRef) -> [RaterTagAffinity] {
        let raterRatings = ratings(for: rater)
        guard raterRatings.count >= minAffinitySampleSize else { return [] }

        let overallAverage = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)

        var scoresByMethodID: [UUID: [Double]] = [:]
        for rating in raterRatings {
            guard let meal = meal(rating.mealID),
                  let recipe = recipe(meal.dishID),
                  let methodID = recipe.cookingMethodID else { continue }
            scoresByMethodID[methodID, default: []].append(rating.reaction.score)
        }

        return scoresByMethodID.compactMap { methodID, scores in
            guard scores.count >= minAffinitySampleSize else { return nil }
            let average = scores.reduce(0, +) / Double(scores.count)
            guard abs(average - overallAverage) >= minAffinityDelta else { return nil }
            let name = taxonomyTerms[methodID]?.name ?? "this cooking method"
            let slug = taxonomyTerms[methodID]?.slug ?? methodID.uuidString
            return RaterTagAffinity(
                kind: .cookingMethod(name: name),
                tag: slug,
                raterAverage: average,
                raterOverallAverage: overallAverage,
                sampleCount: scores.count
            )
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    /// Ingredient affinities where this rater's scores notably deviate from their own average.
    func ingredientAffinities(for rater: RaterRef) -> [RaterTagAffinity] {
        let raterRatings = ratings(for: rater)
        guard raterRatings.count >= minAffinitySampleSize else { return [] }

        let overallAverage = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)

        var scoresByIngredient: [String: [Double]] = [:]
        for rating in raterRatings {
            guard let meal = meal(rating.mealID), let recipe = recipe(meal.dishID) else { continue }
            for ing in canonicalIngredients(for: recipe) {
                scoresByIngredient[ing, default: []].append(rating.reaction.score)
            }
        }

        return scoresByIngredient.compactMap { ing, scores in
            guard scores.count >= minAffinitySampleSize else { return nil }
            let average = scores.reduce(0, +) / Double(scores.count)
            guard abs(average - overallAverage) >= minAffinityDelta else { return nil }
            return RaterTagAffinity(
                kind: .ingredient(name: ing),
                tag: ing,
                raterAverage: average,
                raterOverallAverage: overallAverage,
                sampleCount: scores.count
            )
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    /// Cuisine affinities where this rater's scores notably deviate from their own average.
    func cuisineAffinities(for rater: RaterRef) -> [RaterTagAffinity] {
        let raterRatings = ratings(for: rater)
        guard raterRatings.count >= minAffinitySampleSize else { return [] }

        let overallAverage = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)

        var scoresByCuisine: [String: [Double]] = [:]
        for rating in raterRatings {
            guard let meal = meal(rating.mealID),
                  let recipe = recipe(meal.dishID),
                  let cuisine = recipe.cuisine, !cuisine.isEmpty else { continue }
            for part in Cuisine.parseMultiple(from: cuisine) {
                scoresByCuisine[part.lowercased(), default: []].append(rating.reaction.score)
            }
        }

        return scoresByCuisine.compactMap { cuisine, scores in
            guard scores.count >= minAffinitySampleSize else { return nil }
            let average = scores.reduce(0, +) / Double(scores.count)
            guard abs(average - overallAverage) >= minAffinityDelta else { return nil }
            return RaterTagAffinity(
                kind: .cuisine(name: cuisine),
                tag: cuisine,
                raterAverage: average,
                raterOverallAverage: overallAverage,
                sampleCount: scores.count
            )
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    /// Synthesizes factors explaining one specific meal's verdict for a rater.
    /// Prioritizes dish kind deviation, cooking method, ingredient affinities, cuisine affinities,
    /// and baseline score deviation.
    func raterExplanation(for rater: RaterRef, meal: Meal) -> [RaterTagAffinity] {
        guard let recipe = recipe(meal.dishID) else { return [] }
        var explanations: [RaterTagAffinity] = []

        // 1. Dish Kind factor
        if let kind = dishKind(for: recipe) {
            let kindAffinities = dishKindAffinities(for: rater)
            if let matched = kindAffinities.first(where: { $0.tag == kind.slug }) {
                explanations.append(matched)
            }
        }

        // 2. Cooking Method factor
        if let method = cookingMethod(for: recipe) {
            let methodAffinities = cookingMethodAffinities(for: rater)
            if let matched = methodAffinities.first(where: { $0.tag == method.slug }) {
                explanations.append(matched)
            }
        }

        // 3. Ingredient factors
        let ingredients = canonicalIngredients(for: recipe)
        let ingAffinities = ingredientAffinities(for: rater).filter { ingredients.contains($0.tag) }
        explanations.append(contentsOf: ingAffinities.prefix(2))

        // 4. Cuisine factor
        if let cuisine = recipe.cuisine, !cuisine.isEmpty {
            let cuisines = Cuisine.parseMultiple(from: cuisine).map { $0.lowercased() }
            let matchingCuisines = cuisineAffinities(for: rater).filter { cuisines.contains($0.tag) }
            if let topCuisine = matchingCuisines.first, !explanations.contains(where: { $0.tag == topCuisine.tag }) {
                explanations.append(topCuisine)
            }
        }

        // 5. Baseline comparison if the rating notably deviates from their overall average
        if let rating = rating(for: rater, on: meal.id) {
            let raterRatings = ratings(for: rater)
            if raterRatings.count >= 2 {
                let overallAvg = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)
                let delta = rating.reaction.score - overallAvg
                if abs(delta) >= minAffinityDelta {
                    let baselineAffinity = RaterTagAffinity(
                        kind: .baseline,
                        tag: "baseline",
                        raterAverage: rating.reaction.score,
                        raterOverallAverage: overallAvg,
                        sampleCount: raterRatings.count
                    )
                    if explanations.isEmpty {
                        explanations.append(baselineAffinity)
                    }
                }
            }
        }

        return Array(explanations.prefix(3))
    }

    private func canonicalIngredients(for recipe: Recipe) -> Set<String> {
        Set(recipe.canonicalIngredients.map { $0.lowercased() })
    }
}
