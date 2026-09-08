import SwiftUI

/// Elegant card displaying the average meal rating:
/// - Finely divided between the numerical percentage score and qualitative verdict
/// - Equal visual hierarchy and prominence
/// - Strictly non-interactive (not a button) with no extraneous consensus copy
struct MealDetailAverageRatingCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    private var averageScore: Double? {
        store.averageScore(forMeal: meal.id)
    }

    private var averageReaction: Reaction? {
        store.averageReaction(forMeal: meal.id)
    }

    var body: some View {
        if let score = averageScore, let reaction = averageReaction {
            let percent = Int((score * 100).rounded())
            DividedScoreCard(
                "Average Rating",
                score: "\(percent)",
                verdict: reaction.shortLabel,
                color: reaction.text
            )
        } else {
            DividedScoreCard(
                "Average Rating",
                score: "—",
                verdict: "Unrated",
                color: DS.Color.textTertiary
            )
        }
    }
}
