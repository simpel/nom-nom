import SwiftUI

/// Meal Detail's ScreenHeader, centred on the meal's first photo as its Avatar (the
/// cuisine photo when it has none): the party as the eyebrow (none for a meal of your
/// own), the dish as the title, the date, and "Rate this meal" (or "Change your
/// rating", soft, once you have rated).
struct MealDetailHeader: View {
    let meal: Meal
    /// Nil when the viewer can't rate this meal: the header then has no action.
    let onRate: (() -> Void)?

    @Environment(FoodStore.self) private var store

    var body: some View {
        ScreenHeader(
            store.dishName(forMeal: meal),
            eyebrow: party,
            date: meal.eatenOn,
            avatar: avatar,
            actions: action.map { [$0] } ?? []
        )
    }

    private var avatar: Avatar {
        Avatar(
            name: store.dishName(forMeal: meal),
            photoPath: meal.photoPath,
            bucket: SupabaseConfig.photoBucket,
            assetName: Cuisine.assetImageName(for: store.recipe(meal.recipeID)?.cuisine),
            decorative: true
        )
    }

    /// The context the meal lives in; a meal of your own has none.
    private var party: String? {
        let name = store.partyDisplayName(forMeal: meal)
        return name == "You" ? nil : name
    }

    /// The score is already in the ScoreCard below, so the action names the task, not
    /// a number (DS-GAPS.md B, "Meal header action once rated").
    private var action: ScreenHeaderAction? {
        guard let onRate else { return nil }
        if store.myRating(forMeal: meal.id) != nil {
            return ScreenHeaderAction(title: "Change your rating", appearance: .soft, action: onRate)
        }
        return ScreenHeaderAction(title: "Rate this meal", action: onRate)
    }
}
