// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A horizontal recipe carousel: a DSSection head over a row of `s48` RecipeCards
/// `s3` apart. Placed inside a gutter-padded screen, the row bleeds to the screen
/// edges while the first card lines up with the gutter.
///
/// Tapping a card either pushes `destination` (browse) or calls `onSelect` (picker).
///
/// ```swift
/// RecipeShelf("Popular recipes", recipes: store.popularRecipes) { RecipeDetailView(recipe: $0) }
/// RecipeShelf("Favourites", recipes: favourites, onSelect: { pick($0) })
/// ```
struct RecipeShelf<Destination: View>: View {
    let title: String
    var trailing: String?
    let recipes: [Recipe]
    /// Overrides each card's eyebrow (e.g. "Fits Anna's taste").
    var subtitle: ((Recipe) -> String?)?
    /// Normalised 0–1 score per card; defaults to the dish average.
    var score: ((Recipe) -> Double?)?
    /// Extend the row past the screen gutter.
    var bleeds: Bool
    private let onSelect: ((Recipe) -> Void)?
    private let destination: ((Recipe) -> Destination)?

    /// Browse mode: each card is a NavigationLink to `destination`.
    init(
        _ title: String,
        trailing: String? = nil,
        recipes: [Recipe],
        subtitle: ((Recipe) -> String?)? = nil,
        score: ((Recipe) -> Double?)? = nil,
        bleeds: Bool = true,
        @ViewBuilder destination: @escaping (Recipe) -> Destination
    ) {
        self.title = title
        self.trailing = trailing
        self.recipes = recipes
        self.subtitle = subtitle
        self.score = score
        self.bleeds = bleeds
        self.onSelect = nil
        self.destination = destination
    }

    private var gutter: CGFloat { bleeds ? DS.Spacing.gutter : 0 }

    var body: some View {
        DSSection(title, trailing: trailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: DS.Spacing.s3) {
                    ForEach(recipes) { recipe in
                        cell(recipe)
                    }
                }
                .padding(.horizontal, gutter)
            }
            .padding(.horizontal, -gutter)
        }
    }

    @ViewBuilder
    private func cell(_ recipe: Recipe) -> some View {
        let card = RecipeCard(recipe: recipe, subtitle: subtitle?(recipe), score: score?(recipe))
            .frame(width: DS.Spacing.s48, alignment: .top)
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

extension RecipeShelf where Destination == EmptyView {
    /// Picker mode: tapping a card calls `onSelect`; nil shows the cards inert.
    init(
        _ title: String,
        trailing: String? = nil,
        recipes: [Recipe],
        subtitle: ((Recipe) -> String?)? = nil,
        score: ((Recipe) -> Double?)? = nil,
        bleeds: Bool = true,
        onSelect: ((Recipe) -> Void)?
    ) {
        self.title = title
        self.trailing = trailing
        self.recipes = recipes
        self.subtitle = subtitle
        self.score = score
        self.bleeds = bleeds
        self.onSelect = onSelect
        self.destination = nil
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
                        subtitle: { _ in "Fits her taste" }, score: { _ in 0.86 }, onSelect: { _ in }
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
