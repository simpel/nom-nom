import SwiftUI

/// Section listing meal history on a user profile: thumbnail, name, date and verdict.
/// On your own profile it offers "Log meal"; on someone else's it has no button.
struct ProfileMealHistorySection: View {
    let meals: [Meal]
    let raterRef: RaterRef
    /// `nil` on someone else's profile.
    var onLogMeal: (() -> Void)?

    @Environment(FoodStore.self) private var store

    var body: some View {
        CollectionSection(
            "Meal history",
            count: meals.count,
            verb: "Log meal",
            addLabel: "Log a meal",
            onAdd: onLogMeal,
            emptyTitle: "No meals yet",
            emptyMessage: onLogMeal == nil
                ? "Meals this person has eaten will show up here."
                : "Meals you log will show up here."
        ) {
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

    private func row(for meal: Meal) -> ListRow {
        ListRow(
            store.recipeName(forMeal: meal),
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
            raterRef: .account(store.userID),
            onLogMeal: {}
        )
        .padding(DS.Spacing.gutter)
    }
}
