import SwiftUI

/// One meal in a list: a ListRow with the meal's PhotoCard thumbnail, the dish name,
/// the parties it was served to and its score. Place it in a `Card(layout: .list)`.
struct MealRow: View {
    let meal: Meal
    var raterRef: RaterRef? = nil
    /// Parties only in the meta line and no chevron.
    var isMinimal: Bool = false

    @Environment(FoodStore.self) private var store

    private var ratingSummaryText: String? {
        if let raterRef, let rating = store.rating(for: raterRef, on: meal.id) {
            return rating.reaction.shortLabel
        }
        let ratings = store.ratings(forMeal: meal.id)
        if ratings.count == 1 {
            return ratings.first?.reaction.shortLabel
        } else if ratings.count > 1 {
            return store.averageReaction(forMeal: meal.id)?.shortLabel
        }
        return nil
    }

    private var partyNames: String {
        store.parties(forMeal: meal.id).map(\.name).joined(separator: ", ")
    }

    private var score: Double? {
        if let raterRef, let rating = store.rating(for: raterRef, on: meal.id) {
            return rating.reaction.score
        }
        return store.averageScore(forMeal: meal.id)
    }

    private var meta: String {
        if isMinimal { return partyNames }
        let effort = (meal.effort ?? store.dish(meal.dishID)?.effort)?.label
        return [partyNames, ratingSummaryText, effort]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " \u{00B7} ")
    }

    var body: some View {
        // ListRow has one meta line (README: title + meta), so the cook's notes are
        // left to the meal screen.
        ListRow(
            store.dishName(forMeal: meal),
            meta: meta,
            leading: .photo(.meal(meal)),
            trailing: score.map { .score($0) },
            chevron: !isMinimal
        )
    }
}

#Preview("Minimal") {
    NomNomPreview { store in
        Card(layout: .list) {
            ForEach(store.meals.prefix(3)) { meal in
                MealRow(meal: meal, isMinimal: true)
            }
        }
        .padding(DS.Spacing.gutter)
    }
}

#Preview("Full") {
    NomNomPreview { store in
        Card(layout: .list) {
            ForEach(store.meals.prefix(3)) { meal in
                MealRow(meal: meal)
            }
        }
        .padding(DS.Spacing.gutter)
    }
}
