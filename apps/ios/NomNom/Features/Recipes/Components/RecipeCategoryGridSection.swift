import SwiftUI

/// Every cuisine category as a two-column grid of LabeledPhotoCards, each a link to the
/// category's drill-down. Forwards an optional recipe selection handler (picker mode).
/// Place it inside the screen's gutter padding.
struct RecipeCategoryGridSection: View {
    @Environment(FoodStore.self) private var store

    var title: String = "Categories"
    var onSelectRecipe: ((Recipe) -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.s3),
        GridItem(.flexible(), spacing: DS.Spacing.s3)
    ]

    init(title: String = "Categories", onSelectRecipe: ((Recipe) -> Void)? = nil) {
        self.title = title
        self.onSelectRecipe = onSelectRecipe
    }

    var body: some View {
        DSSection(title) {
            LazyVGrid(columns: columns, spacing: DS.Spacing.s3) {
                ForEach(store.allCategories) { category in
                    NavigationLink {
                        CategoryRecipesView(category: category, onSelectRecipe: onSelectRecipe)
                    } label: {
                        LabeledPhotoCard(
                            .category(category),
                            label: category.displayName,
                            meta: CategoryItem.recipeCountText(store.recipeCount(forCategory: category.name)),
                            fillsWidth: true
                        )
                    }
                    .buttonStyle(AppPressableButtonStyle())
                }
            }
        }
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            ScrollView {
                RecipeCategoryGridSection()
            }
        }
    }
}
