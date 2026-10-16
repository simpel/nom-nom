import SwiftUI

/// The recipes a person created: ListRows (PhotoCard `xs` and the name) that open the
/// recipe. On your own profile the section offers "Add recipe"; on someone else's it has
/// no button.
struct ProfileCreatedRecipesSection: View {
    let recipes: [Recipe]
    /// `nil` on someone else's profile.
    var onCreate: (() -> Void)?

    var body: some View {
        CollectionSection(
            "Created recipes",
            count: recipes.count,
            verb: "Add recipe",
            addLabel: "Add a recipe",
            onAdd: onCreate,
            emptyTitle: "No recipes yet",
            emptyMessage: onCreate == nil
                ? "Recipes this person adds will show up here."
                : "Recipes you add will show up here."
        ) {
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

#Preview {
    NomNomPreview { store in
        ProfileCreatedRecipesSection(recipes: store.recipes, onCreate: {})
            .padding(DS.Spacing.gutter)
    }
}
