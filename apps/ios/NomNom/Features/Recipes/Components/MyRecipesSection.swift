import SwiftUI

/// Section displaying the user's personal recipes in a 2-column minimalist grid.
struct MyRecipesSection: View {
    let recipes: [Recipe]
    var onCreateRecipe: (() -> Void)? = nil

    var body: some View {
        if recipes.isEmpty {
            EmptyState(
                "Create your first recipe",
                message: "Recipes you create will appear here.",
                action: EmptyStateAction(title: "Create recipe", appearance: .solid) { onCreateRecipe?() }
            )
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                HStack {
                    Text("\(recipes.count) recipe\(recipes.count == 1 ? "" : "s")")
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.vertical, DS.Spacing.sm)

                MinimalRecipeGrid(recipes: recipes)
            }
        }
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            ScrollView {
                MyRecipesSection(recipes: [])
            }
        }
    }
}
