import SwiftUI

/// Section listing meal history on a user profile: thumbnail, name, date and verdict.
struct ProfileMealHistorySection: View {
    let meals: [Meal]
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store

    var body: some View {
        if meals.isEmpty {
            SectionCard("Meal History", trailing: "\(meals.count)") {
                EmptyState("No meals logged yet", alignment: .leading, style: .inCard)
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
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func row(for meal: Meal) -> ListRow {
        var row = ListRow(
            store.dishName(forMeal: meal),
            meta: meal.eatenOn.formatted(.dateTime.day().month(.abbreviated).year()),
            leading: .photo(.meal(meal))
        )
        var trailing: [ListRowTrailing] = []
        if let rating = userRating(for: meal) {
            trailing.append(.badge(.verdict(rating, size: .sm)))
        }
        trailing.append(.chevron)
        row.trailing = trailing
        return row
    }

    private func userRating(for meal: Meal) -> Reaction? {
        if let direct = store.rating(for: raterRef, on: meal.id) {
            return direct.reaction
        }
        return store.averageReaction(forMeal: meal.id)
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
