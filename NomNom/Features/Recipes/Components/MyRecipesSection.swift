import SwiftUI

/// Section displaying the user's personal recipes in a 2-column minimalist grid.
struct MyRecipesSection: View {
    let recipes: [Recipe]
    var onCreateRecipe: (() -> Void)? = nil

    var body: some View {
        if recipes.isEmpty {
            ContentUnavailableView {
                Label("No recipes yet", systemImage: "book.closed")
            } description: {
                Text("Recipes you create will appear here.")
            } actions: {
                Button("Create Recipe") {
                    onCreateRecipe?()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 40)
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
                .padding(.vertical, 4)

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
