import SwiftUI

/// Reusable 2-column responsive grid displaying minimalist recipe cards.
struct MinimalRecipeGrid: View {
    let recipes: [Recipe]
    var onSelect: ((Recipe) -> Void)? = nil
    var onNavigate: ((Recipe) -> Void)? = nil

    init(
        recipes: [Recipe],
        onSelect: ((Recipe) -> Void)? = nil,
        onNavigate: ((Recipe) -> Void)? = nil
    ) {
        self.recipes = recipes
        self.onSelect = onSelect
        self.onNavigate = onNavigate
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(recipes) { recipe in
                if let onSelect {
                    Button {
                        onSelect(recipe)
                    } label: {
                        MinimalRecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink {
                        RecipeDetailView(recipeID: recipe.id)
                    } label: {
                        MinimalRecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        onNavigate?(recipe)
                    })
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            ScrollView {
                MinimalRecipeGrid(recipes: [])
            }
        }
    }
}
