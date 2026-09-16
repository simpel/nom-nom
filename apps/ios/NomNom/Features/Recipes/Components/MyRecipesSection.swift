import SwiftUI

/// Section displaying the user's personal recipes in a 2-column minimalist grid.
struct MyRecipesSection: View {
    let recipes: [Recipe]
    var onCreateRecipe: (() -> Void)? = nil

    var body: some View {
        if recipes.isEmpty {
            VStack(spacing: DS.Spacing.section) {
                Spacer(minLength: 20)

                CategoryPhotoArcView()
                    .padding(.vertical, DS.Spacing.sm)

                VStack(spacing: 0) {
                    Text("Create your first recipe")
                        .font(AppTypography.displayL)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("Recipes you create will appear here.")
                        .font(AppTypography.bodyM)
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                }

                AppButton(
                    "Create Recipe",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true,
                    action: { onCreateRecipe?() }
                )
                .frame(maxWidth: 320)
                .padding(.horizontal, 24)
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
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
