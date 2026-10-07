import SwiftUI

/// Key-value details for a recipe: who created it and dish kind. Cuisine,
/// cooking time and method live in the ScreenHeader eyebrow and RecipeDetailFacts;
/// servings sit with the ingredients.
struct RecipeDetailInfoCard: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store
    @State private var showingCreator = false

    private var creatorName: String {
        guard let ownerID = recipe.ownerID else { return "Unknown" }
        if let profile = store.profiles[ownerID] {
            return profile.shownName
        }
        if ownerID == store.userID {
            return store.myProfile?.shownName ?? "You"
        }
        return "Someone"
    }

    var body: some View {
        DSSection("Details") {
            Card(layout: .list) {
                if let ownerID = recipe.ownerID {
                    ListRow("Created by", value: creatorName, chevron: true) {
                        showingCreator = true
                    }
                }

                if let kind = store.dishKind(for: recipe) {
                    ListRow("Dish kind", value: kind.name)
                }
            }
        }
        .sheet(isPresented: $showingCreator) {
            if let ownerID = recipe.ownerID {
                NavigationStack {
                    PersonDetailView(raterRef: .account(ownerID), isSheet: true)
                }
                .dsSheet()
            }
        }
    }
}
