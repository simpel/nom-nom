import SwiftUI

/// The recipe's Facts in a Card (screen anatomy: after the photos): time, method and
/// cuisine. Cuisine is a silent button: it opens that cuisine's recipes in a sheet.
/// Shows nothing when the recipe has none.
struct RecipeDetailFacts: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store
    @State private var openCuisine: CategoryItem?

    private var cuisineName: String? { Cuisine.parseMultiple(from: recipe.cuisine).first }

    private var facts: [Fact] {
        [
            recipe.effort.map { Fact(label: "Time", value: $0.label) },
            store.cookingMethod(for: recipe).map { Fact(label: "Method", value: $0.name) },
            cuisineName.map { Fact(label: "Cuisine", value: CategoryItem(name: $0).displayName) },
        ]
        .compactMap { $0 }
    }

    var body: some View {
        if !facts.isEmpty {
            Card {
                Facts(facts) { fact in
                    guard fact.label == "Cuisine", let cuisineName else { return }
                    openCuisine = CategoryItem(name: cuisineName, photoPath: store.categoryPhotoPaths[cuisineName.lowercased()])
                }
            }
            .sheet(item: $openCuisine) { category in
                NavigationStack {
                    CategoryRecipesView(category: category)
                        .sheetCloseToolbar()
                        .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
                }
                .dsSheet()
            }
        }
    }
}
