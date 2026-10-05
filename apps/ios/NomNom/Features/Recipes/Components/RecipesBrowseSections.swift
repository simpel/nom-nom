import SwiftUI

/// The Recipes tab's shelves ("Nom Nom iOS" canvas): the Pro party card (AI picks, or safe
/// bets as the fallback), My favourites, My recipes (See all, where
/// "New recipe" also lives), Popular recipes and the cuisine categories grid. Empty shelves drop out.
struct RecipesBrowseSections: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if let party = store.currentParty {
                PartyRecommendationsCard(party: party)
            }

            RecipeShelf(
                "My favourites",
                trailing: count(store.favoriteRecipes),
                recipes: store.favoriteRecipes.sorted { $0.createdAt > $1.createdAt }
            ) { RecipeDetailView(recipe: $0) }

            RecipeShelfWithSeeAll(
                title: "My recipes",
                recipes: Array(store.myRecipes.sorted { $0.createdAt > $1.createdAt }.prefix(10)),
                total: store.myRecipes.count
            ) { MyRecipesView() }

            RecipeShelf("Popular recipes", recipes: Array(store.popularRecipes.prefix(10))) {
                RecipeDetailView(recipe: $0)
            }

            RecipeCategoryGridSection()
        }
        .padding(.horizontal, DS.Spacing.gutter)
    }

    private func count(_ recipes: [Recipe]) -> String? {
        recipes.isEmpty ? nil : "\(recipes.count)"
    }
}
