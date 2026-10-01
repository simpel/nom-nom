import SwiftUI

/// A grid or shelf tile for a recipe: a square PhotoCard `md` with the verdict Badge
/// and favourite heart, an uppercase category eyebrow ("by Name" trailing when the
/// owner isn't the viewer) and a two-line `sans-sm` semibold title.
///
/// `s48` wide on its own; a fixed or grid-column width wins. Long-press: add/remove
/// favourite, delete (owner only).
struct RecipeCard<Footer: View>: View {
    let recipe: Recipe
    /// Overrides the eyebrow (otherwise cuisine → dish kind → method → "Recipe").
    var subtitle: String?
    /// Normalised 0–1 score for the verdict Badge; defaults to the dish's average.
    var score: Double?
    var footer: Footer

    @Environment(FoodStore.self) private var store

    init(
        recipe: Recipe,
        subtitle: String? = nil,
        score: Double? = nil,
        @ViewBuilder footer: () -> Footer
    ) {
        self.recipe = recipe
        self.subtitle = subtitle
        self.score = score
        self.footer = footer()
    }

    init(
        recipe: Recipe,
        subtitle: String? = nil,
        score: Double? = nil
    ) where Footer == EmptyView {
        self.init(recipe: recipe, subtitle: subtitle, score: score) { EmptyView() }
    }

    private var category: String {
        if let subtitle, !subtitle.isEmpty { return subtitle }
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

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            PhotoCard(
                .recipe(recipe),
                size: .md,
                fillsWidth: true,
                badge: resolvedScore.map { .score($0) },
                isFavorite: isFavorite,
                accessibilityLabel: recipe.name
            )

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                SectionHeader(category, trailing: creatorLine, inset: false)
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
            Button {
                Task { await store.toggleFavorite(recipe: recipe) }
            } label: {
                Label(
                    isFavorite ? "Remove from Favourites" : "Add to Favourites",
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
                        RecipeCard(recipe: recipe, subtitle: "Weeknight") {
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
