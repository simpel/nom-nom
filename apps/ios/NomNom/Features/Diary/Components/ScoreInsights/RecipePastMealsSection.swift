import SwiftUI

/// "Past meals with this recipe" on the Pro score sheet: how each serving by this group
/// scored, as a TrendChart and a list. Tapping a past meal opens the same MealDetailView
/// used everywhere else, in a sheet. A first serving says so in one row.
struct RecipePastMealsSection: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var openMeal: Meal?

    var body: some View {
        let history = store.partyHistory(for: meal)
        if history.isEmpty {
            DSSection("Past meals with this recipe", trailing: "First time") {
                Card(layout: .list) {
                    EmptyState("The first time you\u{2019}ve had it together", layout: .row)
                }
            }
        } else {
            let servings = ([meal] + history).sorted { $0.eatenOn > $1.eatenOn }
            DSSection("Past meals with this recipe", trailing: "\(servings.count) meals") {
                VStack(spacing: DS.Spacing.s3) {
                    TrendChart(total: points(servings), totalName: "Score", showsPoints: true)
                    Card(layout: .list) {
                        ForEach(servings) { serving in
                            row(serving)
                        }
                    }
                }
            }
            .sheet(item: $openMeal) { past in
                NavigationStack {
                    MealDetailView(mealID: past.id, showCloseButton: true)
                }
            }
        }
    }

    private func points(_ servings: [Meal]) -> [TrendPoint] {
        servings
            .compactMap { serving in
                store.averageScore(forMeal: serving.id).map { TrendPoint(date: serving.eatenOn, value: $0) }
            }
            .sorted { $0.date < $1.date }
    }

    private func row(_ serving: Meal) -> ListRow {
        let isCurrent = serving.id == meal.id
        let count = store.ratings(forMeal: serving.id).count
        let ratings = count == 1 ? "1 rating" : "\(count) ratings"
        return ListRow(
            serving.eatenOn.formatted(date: .abbreviated, time: .omitted),
            meta: isCurrent ? "This time \u{00B7} \(ratings)" : ratings,
            trailing: .score(store.averageScore(forMeal: serving.id)),
            chevron: false,
            action: isCurrent ? nil : { openMeal = serving }
        )
    }
}
