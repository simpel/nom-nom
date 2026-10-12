import Foundation

/// Which "what stood out" tags a meal offers. Tags come from `rating_tags`; a tag is
/// offered for the verdicts it names, on recipes whose kind or cooking method carries
/// its trait. Traits live on the taxonomy terms, so a new recipe kind needs no app change.
extension FoodStore {

    /// What the meal's recipe is like (`crust`, `saucy`, `raw`, …), from its recipe kind
    /// and cooking method. Empty when the recipe has neither: the meal then offers the
    /// tags that fit any cooked recipe.
    func ratingTraits(forMeal mealID: UUID) -> Set<String> {
        guard let meal = meal(mealID), let recipe = recipe(meal.recipeID) else { return [] }
        let terms = [recipeKind(for: recipe), cookingMethod(for: recipe)].compactMap { $0 }
        return Set(terms.flatMap(\.ratingTraits))
    }

    /// The tags offered for this verdict on a recipe with these traits: good tags first for
    /// Good and up, problems first below it.
    func ratingTagOptions(for reaction: Reaction, traits: Set<String>) -> [RatingTagOption] {
        let offered = ratingTags.filter { $0.isOffered(for: reaction, traits: traits) }
        let liked = reaction >= .good
        return offered.filter { $0.isPositive == liked } + offered.filter { $0.isPositive != liked }
    }

    /// The labels of these tag ids, in catalogue order.
    func ratingTagLabels(_ ids: some Collection<String>) -> [String] {
        let chosen = Set(ids)
        return ratingTags.filter { chosen.contains($0.id) }.map(\.label)
    }
}
