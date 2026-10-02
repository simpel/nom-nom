import SwiftUI

/// The Recipes tab's shelves ("Nom Nom iOS" canvas): Pro "Recommended for you", My
/// favourites, My recipes (See all), Safe bets for the party, Popular everywhere and
/// the cuisine categories grid. Empty shelves drop out.
struct RecipesBrowseSections: View {
    @Environment(FoodStore.self) private var store

    private var who: String { store.currentParty?.name ?? "you" }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if !store.recommendedRecipes.isEmpty {
                ProSection(
                    "Recommended for you",
                    teaser: "Recipes picked from what \(who) rates highest and what you haven\u{2019}t had for a while.",
                    contentBleed: DS.Spacing.s5
                ) {
                    RecipeShelf("", recipes: store.recommendedRecipes, bleed: DS.Spacing.s5) { RecipeDetailView(recipe: $0) }
                }
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

            if let party = store.currentParty {
                let safe = store.safeBetRecipes(forParty: party.id)
                RecipeShelf(
                    "Safe bets for \(party.name)",
                    trailing: count(safe),
                    recipes: safe,
                    score: { store.partyScore(forRecipe: $0.id, partyID: party.id) }
                ) { RecipeDetailView(recipe: $0) }
            }

            RecipeShelf("Popular everywhere", recipes: Array(store.popularRecipes.prefix(10))) {
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
