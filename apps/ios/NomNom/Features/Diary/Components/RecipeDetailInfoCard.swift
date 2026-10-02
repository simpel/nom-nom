import SwiftUI

/// Key-value details for a recipe: who created it, servings and dish kind. Cuisine,
/// cooking time and method live in the DetailHeader (eyebrow and fact Badges).
struct RecipeDetailInfoCard: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store

    private var creatorName: String {
        if let profile = store.profiles[recipe.ownerID] {
            return profile.shownName
        }
        if recipe.ownerID == store.userID {
            return store.myProfile?.shownName ?? "You"
        }
        return "Someone"
    }

    var body: some View {
        DSSection("Details") {
            Card(layout: .list) {
                NavigationLink {
                    PersonDetailView(raterRef: .account(recipe.ownerID))
                } label: {
                    ListRow("Created by", trailing: .value(creatorName), .chevron)
                }
                .buttonStyle(AppPressableButtonStyle())

                if let serves = recipe.serves {
                    ListRow("Servings", trailing: .value(serves == 1 ? "1 serving" : "\(serves) servings"))
                }

                if let kind = store.dishKind(for: recipe) {
                    ListRow("Dish kind", trailing: .badge(Badge(kind.name, variant: .secondary, size: .sm)))
                }
            }
        }
    }
}
