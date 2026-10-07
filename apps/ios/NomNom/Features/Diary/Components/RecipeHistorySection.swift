import SwiftUI

/// Every time the recipe was cooked: a Timeline (photos and verdicts, oldest to
/// newest), then a ListRow list newest first with who it was cooked for, which the
/// Timeline can't show. The list loads 10 more rows as its last row appears.
struct RecipeHistorySection: View {
    /// Servings, newest first.
    let history: [Meal]
    let onSelectMeal: (Meal) -> Void

    @Environment(FoodStore.self) private var store
    @State private var displayLimit = Self.pageSize

    private static let pageSize = 10

    private var visibleMeals: [Meal] { Array(history.prefix(displayLimit)) }

    private var occasions: [TimelineOccasion] {
        history.reversed().map { meal in
            TimelineOccasion(
                id: AnyHashable(meal.id),
                date: meal.eatenOn,
                score: store.averageScore(forMeal: meal.id),
                photo: .meal(meal)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            Timeline(occasions: occasions, title: "Every time \(store.currentParty?.name ?? "you") cooked it") { id in
                if let meal = history.first(where: { AnyHashable($0.id) == id }) {
                    onSelectMeal(meal)
                }
            }

            DSSection("Cooked for", trailing: history.count == 1 ? "1 meal" : "\(history.count) meals") {
                Card(layout: .list) {
                    ForEach(visibleMeals) { meal in
                        row(for: meal)
                            .onAppear { loadMoreIfNeeded(after: meal) }
                    }
                }
            }
        }
    }

    private func row(for meal: Meal) -> some View {
        ListRow(
            meal.eatenOn.formatted(.dateTime.day().month(.abbreviated).year()),
            meta: subtitle(for: meal),
            leading: .photo(.meal(meal)),
            trailing: .score(store.averageScore(forMeal: meal.id)),
            action: { onSelectMeal(meal) }
        )
    }

    private func subtitle(for meal: Meal) -> String? {
        let partyNames = store.parties(forMeal: meal.id).map(\.name).joined(separator: ", ")
        if !partyNames.isEmpty { return partyNames }
        if meal.createdBy == store.userID { return "Cooked by you" }
        guard let createdBy = meal.createdBy else { return nil }
        return "Cooked by \(store.label(for: .account(createdBy)).name)"
    }

    private func loadMoreIfNeeded(after meal: Meal) {
        if meal.id == visibleMeals.last?.id && displayLimit < history.count {
            displayLimit += Self.pageSize
        }
    }
}
