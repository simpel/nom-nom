import SwiftUI

/// Section listing meal history on a user profile: thumbnail, name, date and verdict.
struct ProfileMealHistorySection: View {
    let meals: [Meal]
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store

    var body: some View {
        if meals.isEmpty {
            DSSection("Meal History", trailing: "\(meals.count)") {
                EmptyState("No meals yet", message: "Meals this person has eaten will show up here.")
            }
        } else {
            DSSection("Meal History", trailing: "\(meals.count)") {
                Card(layout: .list) {
                    ForEach(meals) { meal in
                        NavigationLink {
                            MealDetailView(mealID: meal.id)
                        } label: {
                            row(for: meal)
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                }
            }
        }
    }

    private func row(for meal: Meal) -> ListRow {
        ListRow(
            store.dishName(forMeal: meal),
            meta: meal.eatenOn.formatted(.dateTime.day().month(.abbreviated).year()),
            leading: .photo(.meal(meal)),
            trailing: userScore(for: meal).map { .score($0) },
            chevron: true
        )
    }

    /// This person's score for the meal, number only; the meal's when they didn't rate.
    private func userScore(for meal: Meal) -> Double? {
        store.rating(for: raterRef, on: meal.id)?.score ?? store.averageScore(forMeal: meal.id)
    }
}

#Preview {
    NomNomPreview { store in
        ProfileMealHistorySection(
            meals: store.meals,
            raterRef: .account(store.userID)
        )
        .padding(DS.Spacing.gutter)
    }
}
