import SwiftUI

/// A RecipeShelf whose header ends in the section action "See all" (a soft capsule, the
/// same as every section verb) to the full list — "My recipes" on the Recipes tab. The
/// shelf is hidden while empty.
struct RecipeShelfWithSeeAll<Destination: View>: View {
    let title: String
    let recipes: [Recipe]
    @ViewBuilder let seeAll: () -> Destination

    var body: some View {
        if !recipes.isEmpty {
            DSSection(title, action: SectionAction(link: "See all", accessibilityLabel: "See all \(title)", destination: seeAll)) {
                RecipeShelf("", recipes: recipes) { RecipeDetailView(recipe: $0) }
            }
        }
    }
}
