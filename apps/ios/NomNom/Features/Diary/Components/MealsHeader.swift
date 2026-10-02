import SwiftUI

/// The top of the Meals tab ("Nom Nom iOS" canvas): a DetailHeader with the party as
/// meta, "Meals" as the title, "{party} has logged 16 meals, 4 of them this week." and
/// one solid "Log a meal" action.
struct MealsHeader: View {
    let onLogMeal: () -> Void

    @Environment(FoodStore.self) private var store

    var body: some View {
        HStack(alignment: .bottom, spacing: DS.Spacing.s3) {
            PageHeader("Meals", eyebrow: store.currentParty?.name)
            AppButton("Log a meal", icon: "plus", action: onLogMeal)
        }
    }
}
