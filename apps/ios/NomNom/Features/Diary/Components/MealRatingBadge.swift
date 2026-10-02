import SwiftUI

/// A meal's rating at a glance: the rotation goal Badge, then a verdict Badge for a
/// single rating, the average ScoreValue for several, or an "Unrated" Badge (README
/// "Unrated is a real state": `sunken` ground, `text-tertiary`, dashed circle).
struct MealRatingBadge: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    var body: some View {
        HStack(spacing: DS.Spacing.s1_5) {
            if let rotation = store.averageRotation(forMeal: meal.id) {
                Badge.rotation(rotation)
            }

            let ratings = store.ratings(forMeal: meal.id)
            if ratings.isEmpty {
                Badge("Unrated", icon: "circle.dashed", variant: .secondary, size: .sm)
            } else if ratings.count == 1, let single = ratings.first?.reaction {
                Badge.verdict(single, size: .sm)
            } else if let score = store.averageScore(forMeal: meal.id) {
                ScoreValue(score: score, size: .xs, showVerdict: false)
            }
        }
    }
}
