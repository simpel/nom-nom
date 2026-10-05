import SwiftUI

/// Every recipe you added, newest first: "See all" from the Recipes tab's My recipes shelf.
/// The ScreenHeader carries "New recipe" (the Recipes tab itself has no create action);
/// with no recipes yet, the EmptyState's "Add recipe" does that job instead.
struct MyRecipesView: View {
    @Environment(FoodStore.self) private var store
    @State private var showingCreateSheet = false

    private var recipes: [Recipe] { store.myRecipes.sorted { $0.createdAt > $1.createdAt } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                ScreenHeader(
                    "My recipes",
                    eyebrow: "Recipes",
                    actions: recipes.isEmpty ? [] : [ScreenHeaderAction(title: "New recipe") { showingCreateSheet = true }]
                )
                .padding(.horizontal, DS.Spacing.gutter)

                MyRecipesSection(recipes: recipes, onCreateRecipe: { showingCreateSheet = true })
            }
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .screenTitle("", displayMode: .inline)
        .sheet(isPresented: $showingCreateSheet) { CreateRecipeSheet() }
    }
}
