import SwiftUI

/// Horizontal scroll shelf displaying curated recipes in minimal cards.
/// Supports both navigation drill-down (browse mode) and closure-based selection (picker mode).
struct RecipeHorizontalShelf: View {
    let title: String
    let recipes: [Recipe]
    var onSelect: ((Recipe) -> Void)? = nil

    init(title: String, recipes: [Recipe], onSelect: ((Recipe) -> Void)? = nil) {
        self.title = title
        self.recipes = recipes
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(recipes) { recipe in
                        if let onSelect {
                            Button {
                                onSelect(recipe)
                            } label: {
                                MinimalRecipeCard(recipe: recipe)
                                    .frame(width: 156, height: 220, alignment: .top)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                RecipeDetailView(recipeID: recipe.id)
                            } label: {
                                MinimalRecipeCard(recipe: recipe)
                                    .frame(width: 156, height: 220, alignment: .top)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            RecipeHorizontalShelf(title: "Popular Recipes", recipes: [])
        }
    }
}
