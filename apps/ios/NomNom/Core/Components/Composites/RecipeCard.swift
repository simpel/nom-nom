import SwiftUI

/// A grid or shelf tile for a recipe (components/RecipeCard/README.md): a square
/// PhotoCard `md` with the verdict Badge and the favourite heart, an uppercase category
/// SectionHeader ("by Name" trailing when the owner isn't the viewer) and a two-line
/// `sans-sm` semibold title, the label block a fixed `s14` so rows align.
///
/// `s48` wide on its own; a fixed or grid-column width wins at the same 1:1 ratio.
/// The heart toggles the favourite (outlined until it is one). Long-press: add/remove
/// favourite, delete (owner only).
struct RecipeCard<Footer: View>: View {
    let recipe: Recipe
    /// Overrides the eyebrow (otherwise cuisine → dish kind → method → "Recipe").
    var category: String?
    /// Normalised 0–1 score for the verdict Badge; defaults to the dish's average.
    var score: Double?
    var footer: Footer

    @Environment(FoodStore.self) private var store

    init(
        recipe: Recipe,
        category: String? = nil,
        score: Double? = nil,
        @ViewBuilder footer: () -> Footer
    ) {
        self.recipe = recipe
        self.category = category
        self.score = score
        self.footer = footer()
    }

    init(
        recipe: Recipe,
        category: String? = nil,
        score: Double? = nil
    ) where Footer == EmptyView {
        self.init(recipe: recipe, category: category, score: score) { EmptyView() }
    }

    private var eyebrow: String {
        if let category, !category.isEmpty { return category }
        if let cuisine = Cuisine.formatDisplayName(recipe.cuisine) { return cuisine }
        if let kind = store.dishKind(for: recipe) { return kind.name }
        if let method = store.cookingMethod(for: recipe) { return method.name }
        return "Recipe"
    }

    private var creatorLine: String? {
        guard recipe.ownerID != store.userID,
              let creator = store.profiles[recipe.ownerID]?.shortName else { return nil }
        return "by \(creator)"
    }

    private var resolvedScore: Double? {
        score ?? store.averageScore(forDish: recipe.id)
    }

    private var isFavorite: Bool { store.isFavorite(recipe: recipe) }

    private func toggleFavorite() {
        Task { await store.toggleFavorite(recipe: recipe) }
    }

    var body: some View {
        // bundle.css `.nn-recipe-card { gap: var(--spacing-1\.5) }`.
        VStack(alignment: .leading, spacing: DS.Spacing.s1_5) {
            PhotoCard(
                .recipe(recipe),
                size: .md,
                format: .square,
                fillsWidth: true,
                badge: resolvedScore.map { .score($0) },
                isFavorite: isFavorite,
                onToggleFavorite: toggleFavorite,
                accessibilityLabel: recipe.name
            )

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                SectionHeader(title: eyebrow, trailing: creatorLine)
                Text(recipe.name)
                    .textStyle(.sansSm, weight: .semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            // Fixed `s14` so rows align; `minHeight` so two lines at large type never overlap the footer.
            .frame(minHeight: DS.Spacing.s14, alignment: .topLeading)

            if Footer.self != EmptyView.self {
                footer
            }
        }
        .frame(idealWidth: DS.Spacing.s48, maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: toggleFavorite) {
                Label(
                    isFavorite ? "Remove from favourites" : "Add to favourites",
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }

            if recipe.ownerID == store.userID {
                Button(role: .destructive) {
                    Task { await store.delete(recipe: recipe) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct RecipeCardGallery: View {
    var body: some View {
        NomNomPreview(inNavigationStack: false) { store in
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible())],
                    spacing: DS.Spacing.s4
                ) {
                    ForEach(store.recipes.prefix(4)) { recipe in
                        RecipeCard(recipe: recipe, score: 0.8)
                    }
                    if let recipe = store.recipes.first {
                        RecipeCard(recipe: recipe, category: "Weeknight") {
                            Text("Fits the household's taste").textStyle(.sansSm, tone: .tertiary)
                        }
                    }
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { RecipeCardGallery() }
#Preview("Dark") { RecipeCardGallery().preferredColorScheme(.dark) }
