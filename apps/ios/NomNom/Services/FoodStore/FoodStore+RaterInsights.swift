import Foundation

/// On-device, deterministic "why did they score it that way" analysis. No LLM call —
/// same confidence-gated spirit as `SuggestionEngine.reasons(...)`: don't surface a claim
/// without enough samples and a real deviation from the rater's own baseline.
extension FoodStore {

    private var minAffinitySampleSize: Int { 3 }
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

    /// Tags/ingredients where this rater's average score notably deviates from their own
    /// overall average, ranked by strength of deviation. Requires a minimum sample size per
    /// tag before surfacing a claim.
    func tagAffinities(for rater: RaterRef) -> [RaterTagAffinity] {
        let raterRatings = ratings(for: rater)
        guard raterRatings.count >= minAffinitySampleSize else { return [] }

        let overallAverage = raterRatings.map(\.reaction.score).reduce(0, +) / Double(raterRatings.count)

        var scoresByTag: [String: [Double]] = [:]
        for rating in raterRatings {
            guard let meal = meal(rating.mealID), let recipe = recipe(meal.dishID) else { continue }
            for tag in tags(for: recipe) {
                scoresByTag[tag, default: []].append(rating.reaction.score)
            }
        }

        return scoresByTag.compactMap { tag, scores in
            guard scores.count >= minAffinitySampleSize else { return nil }
            let average = scores.reduce(0, +) / Double(scores.count)
            guard abs(average - overallAverage) >= minAffinityDelta else { return nil }
            return RaterTagAffinity(
                tag: tag,
                raterAverage: average,
                raterOverallAverage: overallAverage,
                sampleCount: scores.count
            )
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    /// Affinities relevant to one specific meal's recipe, for the "why this score" UI.
    /// Top 3, strongest deviation first.
    func raterExplanation(for rater: RaterRef, meal: Meal) -> [RaterTagAffinity] {
        guard let recipe = recipe(meal.dishID) else { return [] }
        let mealTags = tags(for: recipe)
        return Array(tagAffinities(for: rater).filter { mealTags.contains($0.tag) }.prefix(3))
    }

    /// Tags as-is (already close to a controlled vocabulary) plus `canonicalIngredients` —
    /// LLM-normalized core ingredient categories generated during health analysis (see
    /// `HealthIndex.canonicalIngredients`), so variants of the same ingredient (e.g.
    /// "chicken breast" and "boneless chicken thighs") land in one bucket instead of staying
    /// separate, near-unique strings that never accumulate enough repeat samples. Empty for
    /// recipes not yet analyzed — same silent-backfill gap `healthIndex` already has.
    private func tags(for recipe: Recipe) -> Set<String> {
        Set(recipe.tags.map { $0.lowercased() } + recipe.canonicalIngredients.map { $0.lowercased() })
    }
}
