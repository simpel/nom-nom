import SwiftUI

/// Every time this group cooked the recipe, oldest first, with this meal selected.
/// Past stops call `onOpenMeal` with their meal id.
struct MealDetailTimeline: View {
    let meal: Meal
    let history: [Meal]
    let onOpenMeal: (UUID) -> Void

    @Environment(FoodStore.self) private var store

    private var occasions: [TimelineOccasion] {
        (history + [meal])
            .sorted { $0.eatenOn < $1.eatenOn }
            .map { serving in
                TimelineOccasion(
                    id: AnyHashable(serving.id),
                    date: serving.eatenOn,
                    score: store.averageScore(forMeal: serving.id),
                    photo: .meal(serving),
                    isCurrent: serving.id == meal.id
                )
            }
    }

    var body: some View {
        Timeline(occasions: occasions) { id in
            if let mealID = id.base as? UUID { onOpenMeal(mealID) }
        }
    }
}
