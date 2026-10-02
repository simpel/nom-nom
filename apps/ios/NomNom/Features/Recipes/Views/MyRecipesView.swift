import SwiftUI

/// Every recipe you added, newest first: "See all" from the Recipes tab's My recipes shelf.
struct MyRecipesView: View {
    @Environment(FoodStore.self) private var store
    @State private var showingCreateSheet = false

    var body: some View {
        ScrollView {
            MyRecipesSection(
                recipes: store.myRecipes.sorted { $0.createdAt > $1.createdAt },
                onCreateRecipe: { showingCreateSheet = true }
            )
            .padding(.top, DS.Spacing.s3)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .screenTitle("My recipes", displayMode: .inline)
        .sheet(isPresented: $showingCreateSheet) { CreateRecipeSheet() }
    }
}
