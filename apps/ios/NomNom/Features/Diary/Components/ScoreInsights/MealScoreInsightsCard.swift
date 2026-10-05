import SwiftUI

/// The Pro block on the meal score sheet, under the hero ("Nom Nom iOS" score canvas,
/// board 1): "Why it landed at 15" and one sentence of insight (`MealScoreInsight`).
/// Locked, ProCard blurs the sentence behind "Unlock with Pro"; with Pro the whole card
/// is pressable and opens `MealScoreInsightsSheet`. Hidden until the meal has a rating.
struct MealScoreInsightsCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var showInsights = false

    var body: some View {
        if let score = store.averageScore(forMeal: meal.id) {
            let points = Int((score * 100).rounded())
            ProCard(
                "Why it landed at \(points)",
                teaser: "See what in this party\u{2019}s history explains the score: what pulled it down, what to change next time and how it has scored before.",
                action: { showInsights = true }
            ) {
                Text(store.scoreInsight(forMeal: meal))
                    .textStyle(.sansMd, tone: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .sheet(isPresented: $showInsights) {
                MealScoreInsightsSheet(meal: meal)
            }
        }
    }
}
