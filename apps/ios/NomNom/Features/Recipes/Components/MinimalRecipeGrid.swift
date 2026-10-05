import SwiftUI

/// Two-column grid of RecipeCards inside the screen gutter (RecipeCard README: "In a
/// grid the card fills its column at the same ratio"), `spacing-3` apart like the
/// category grid. With a `title` the grid is a DSSection whose trailing figure is the
/// recipe count.
struct MinimalRecipeGrid: View {
    let recipes: [Recipe]
    var title: String?
    var onSelect: ((Recipe) -> Void)?
    var onNavigate: ((Recipe) -> Void)?

    init(
        recipes: [Recipe],
        title: String? = nil,
        onSelect: ((Recipe) -> Void)? = nil,
        onNavigate: ((Recipe) -> Void)? = nil
    ) {
        self.recipes = recipes
        self.title = title
        self.onSelect = onSelect
        self.onNavigate = onNavigate
    }

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.s3),
        GridItem(.flexible(), spacing: DS.Spacing.s3)
    ]

    var body: some View {
        Group {
            if let title {
                DSSection(title, trailing: "\(recipes.count)") { grid }
            } else {
                grid
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s3) {
            ForEach(recipes) { recipe in
                if let onSelect {
                    Button {
                        onSelect(recipe)
                    } label: {
                        RecipeCard(recipe: recipe)
                    }
                    .buttonStyle(AppPressableButtonStyle())
                } else {
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeCard(recipe: recipe)
                    }
                    .buttonStyle(AppPressableButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        onNavigate?(recipe)
                    })
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        NavigationStack {
            ScrollView {
                MinimalRecipeGrid(recipes: Array(store.recipes.prefix(4)), title: "Favourites")
            }
            .background(DS.Color.bg)
        }
    }
}
