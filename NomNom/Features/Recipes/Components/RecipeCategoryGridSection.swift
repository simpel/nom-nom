import SwiftUI

/// Reusable 2-column grid section displaying all cuisine categories.
/// Seamlessly forwards optional recipe selection handler to category drill-down screens.
struct RecipeCategoryGridSection: View {
    @Environment(FoodStore.self) private var store

    var title: String = "Categories"
    var onSelectRecipe: ((Recipe) -> Void)? = nil

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(title: String = "Categories", onSelectRecipe: ((Recipe) -> Void)? = nil) {
        self.title = title
        self.onSelectRecipe = onSelectRecipe
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title)

            LazyVGrid(columns: categoryColumns, spacing: 12) {
                ForEach(Cuisine.allCases) { cuisine in
                    let count = store.recipeCount(forCategory: cuisine.rawValue)
                    NavigationLink {
                        CategoryRecipesView(cuisine: cuisine, onSelectRecipe: onSelectRecipe)
                    } label: {
                        CategoryGridCard(cuisine: cuisine, count: count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
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
