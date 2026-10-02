import SwiftUI

/// One AI recommendation in a RecipeShelf: the recipe's RecipeCard (a link into it)
/// with the description as its footer, or, when there is no recipe yet, the same
/// layout drawn on the cuisine photo.
///
/// ```swift
/// RecipeShelf("AI recipe recommendations", items: recommendations) { RecommendationShelfCard(rec: $0) }
/// ```
struct RecommendationShelfCard: View {
    let rec: PartyInsightRecommendation

    @Environment(FoodStore.self) private var store

    var body: some View {
        if let dishID = rec.dishID, let recipe = store.recipe(dishID) {
            NavigationLink(value: InsightsRoute.dish(dishID)) {
                RecipeCard(recipe: recipe, category: rec.cuisine) { description }
            }
            .buttonStyle(AppPressableButtonStyle())
        } else {
            idea
        }
    }

    private var description: some View {
        Text(rec.description).textStyle(.sansSm, tone: .secondary, lines: 3)
    }

    /// RecipeCard's layout (PhotoCard `md` on the cuisine photo, category SectionHeader,
    /// two-line title in a `spacing-14` block) at RecipeCard's `spacing-48` width.
    private var idea: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1_5) {
            PhotoCard(.none(cuisine: rec.cuisine), size: .md, fillsWidth: true, accessibilityLabel: rec.title)

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                SectionHeader(title: rec.cuisine ?? "Recipe")
                Text(rec.title)
                    .textStyle(.sansSm, weight: .semibold, lines: 2)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: DS.Spacing.s14, alignment: .topLeading)

            description
        }
        .frame(width: DS.Spacing.s48, alignment: .leading)
        .contentShape(Rectangle())
    }
}
