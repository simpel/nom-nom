import SwiftUI

/// A section header over a horizontal row of RecipeCards: the one recipe carousel
/// (components/RecipeShelf/README.md). Built from DSSection, RecipeCard and EmptyState.
///
/// - Cards are RecipeCard at its own size; the shelf sets no dimensions.
/// - The track is `spacing-3` between cards (bundle.css `.nn-shelf__track`), snaps to
///   each card and bleeds past the gutter like PhotoStrip and Timeline. Place the shelf
///   inside the screen's gutter padding; `bleed` is how far the track reaches past it.
/// - No recipes: the `emptyState` instead of the track, or nothing at all.
///
/// ```swift
/// RecipeShelf("Popular recipes", recipes: store.popularRecipes) { RecipeDetailView(recipe: $0) }
/// RecipeShelf("Favourites", recipes: favourites, onSelect: { pick($0) })
/// RecipeShelf("Ideas", items: ideas) { idea in RecipeCard(recipe: idea.recipe) }
/// ```
struct RecipeShelf<Item: Identifiable, Cell: View>: View {
    let title: String
    var trailing: String?
    let items: [Item]
    var emptyState: EmptyState?
    var bleed: CGFloat
    private let cell: (Item) -> Cell

    /// The general shape: one RecipeCard (as a link, a button or plain) per item.
    init(
        _ title: String,
        trailing: String? = nil,
        items: [Item],
        emptyState: EmptyState? = nil,
        bleed: CGFloat = DS.Spacing.gutter,
        @ViewBuilder cell: @escaping (Item) -> Cell
    ) {
        self.title = title
        self.trailing = trailing
        self.items = items
        self.emptyState = emptyState
        self.bleed = bleed
        self.cell = cell
    }

    var body: some View {
        if !items.isEmpty {
            if title.isEmpty {
                track
            } else {
                DSSection(title, trailing: trailing) { track }
            }
        } else if let emptyState {
            DSSection(title, trailing: trailing) { emptyState }
        }
    }

    /// An empty `title` drops the header (a shelf inside a titled ProSection).
    private var track: some View {
        // README: "touch gets the platform's own" bar, so the system indicator stays on.
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: DS.Spacing.s3) {
                ForEach(items) { cell($0) }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, bleed, for: .scrollContent)
        .padding(.horizontal, -bleed)
    }
}

/// One RecipeShelf card: a NavigationLink to `destination`, a button calling
/// `onSelect`, or a plain card when it has nowhere to go.
struct RecipeShelfCard<Destination: View>: View {
    let recipe: Recipe
    var category: String?
    var score: Double?
    var onSelect: ((Recipe) -> Void)?
    var destination: ((Recipe) -> Destination)?

    var body: some View {
        let card = RecipeCard(recipe: recipe, category: category, score: score)
        if let onSelect {
            Button { onSelect(recipe) } label: { card }
                .buttonStyle(AppPressableButtonStyle())
        } else if let destination {
            NavigationLink { destination(recipe) } label: { card }
                .buttonStyle(AppPressableButtonStyle())
        } else {
            card
        }
    }
}

extension RecipeShelf where Item == Recipe {
    /// Browse: each card pushes `destination`.
    init<Destination: View>(
        _ title: String,
        trailing: String? = nil,
        recipes: [Recipe],
        category: ((Recipe) -> String?)? = nil,
        score: ((Recipe) -> Double?)? = nil,
        emptyState: EmptyState? = nil,
        bleed: CGFloat = DS.Spacing.gutter,
        @ViewBuilder destination: @escaping (Recipe) -> Destination
    ) where Cell == RecipeShelfCard<Destination> {
        self.init(title, trailing: trailing, items: recipes, emptyState: emptyState, bleed: bleed) { recipe in
            RecipeShelfCard(recipe: recipe, category: category?(recipe), score: score?(recipe), destination: destination)
        }
    }

    /// Pick: each card calls `onSelect`; `nil` shows plain cards.
    init(
        _ title: String,
        trailing: String? = nil,
        recipes: [Recipe],
        category: ((Recipe) -> String?)? = nil,
        score: ((Recipe) -> Double?)? = nil,
        emptyState: EmptyState? = nil,
        bleed: CGFloat = DS.Spacing.gutter,
        onSelect: ((Recipe) -> Void)?
    ) where Cell == RecipeShelfCard<EmptyView> {
        self.init(title, trailing: trailing, items: recipes, emptyState: emptyState, bleed: bleed) { recipe in
            RecipeShelfCard<EmptyView>(recipe: recipe, category: category?(recipe), score: score?(recipe), onSelect: onSelect)
        }
    }
}

private struct RecipeShelfGallery: View {
    var body: some View {
        NomNomPreview { store in
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    RecipeShelf("Popular recipes", trailing: "\(store.recipes.count)", recipes: store.recipes) { recipe in
                        Text(recipe.name)
                    }
                    RecipeShelf(
                        "Picks for Anna", recipes: Array(store.recipes.prefix(3)),
                        category: { _ in "Fits her taste" }, score: { _ in 0.86 }, onSelect: { _ in }
                    )
                    RecipeShelf(
                        "Cooked recently", recipes: [],
                        emptyState: EmptyState("No recipes yet", message: "Log a meal to see it here."),
                        onSelect: nil
                    )
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { RecipeShelfGallery() }
#Preview("Dark") { RecipeShelfGallery().preferredColorScheme(.dark) }
