import SwiftUI

/// How this group scored the dish before: a compact ScoreCard with the historical
/// average (delta = this meal vs that average), then the latest past servings as
/// ListRows in a list Card. A first serving gets a short note instead.
struct MealHistoricalScoresCard: View {
    let currentMeal: Meal
    /// Other servings by the same group, newest first (`FoodStore.partyHistory(for:)`).
    let history: [Meal]

    @Environment(FoodStore.self) private var store

    private var trailing: String {
        if history.isEmpty { return "First time" }
        return history.count == 1 ? "1 past time" : "\(history.count) past times"
    }

    var body: some View {
        if history.isEmpty {
            // EmptyState "Not enough data yet": no action, waiting is the answer.
            DSSection("Historical scores", trailing: trailing) {
                EmptyState(
                    "First time with this recipe",
                    message: "Comparisons show up the next time your dinner party logs it."
                )
            }
        } else {
            DSSection("Historical scores", trailing: trailing) {
                VStack(spacing: DS.Spacing.s3) {
                    if let average = store.averageScore(across: history) {
                        ScoreCard(
                            score: average,
                            layout: .compact,
                            title: "Historical average",
                            delta: deltaVsAverage(average)
                        )
                    }
                    Card(layout: .list) {
                        ForEach(history.prefix(6)) { past in
                            ListRow(
                                past.eatenOn.formatted(.dateTime.day().month(.abbreviated).year()),
                                meta: cookLine(for: past),
                                trailing: .score(store.averageScore(forMeal: past.id))
                            )
                        }
                    }
                }
            }
        }
    }

    private func deltaVsAverage(_ average: Double) -> Int? {
        guard let current = store.averageScore(forMeal: currentMeal.id) else { return nil }
        return Int(((current - average) * 100).rounded())
    }

    private func cookLine(for meal: Meal) -> String {
        if meal.createdBy == store.userID { return "Cooked by you" }
        return "Cooked by \(store.label(for: .account(meal.createdBy)).name)"
    }
}
