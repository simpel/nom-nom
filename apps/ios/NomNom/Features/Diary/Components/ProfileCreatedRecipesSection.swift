import SwiftUI

/// The recipes a person created: a DSSection over ListRows (PhotoCard `xs` and the
/// name) that open the recipe, or an EmptyState when there are none.
struct ProfileCreatedRecipesSection: View {
    let recipes: [Recipe]

    var body: some View {
        DSSection("Created recipes", trailing: "\(recipes.count)") {
            if recipes.isEmpty {
                EmptyState("No recipes yet", message: "Recipes this person adds will show up here.")
            } else {
                Card(layout: .list) {
                    ForEach(recipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            ListRow(recipe.name, leading: .photo(.recipe(recipe)), chevron: true)
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        ProfileCreatedRecipesSection(recipes: store.recipes)
            .padding(DS.Spacing.gutter)
    }
}
