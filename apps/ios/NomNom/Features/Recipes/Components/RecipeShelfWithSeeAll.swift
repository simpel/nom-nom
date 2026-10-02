import SwiftUI

/// A RecipeShelf whose header ends in a "See all N" link (`sans-xs` `primary-text`)
/// to the full list — "My recipes" on the Recipes tab.
struct RecipeShelfWithSeeAll<Destination: View>: View {
    let title: String
    let recipes: [Recipe]
    var total: Int
    @ViewBuilder let seeAll: () -> Destination

    var body: some View {
        if !recipes.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                HStack(alignment: .firstTextBaseline) {
                    SectionHeader(title: title)
                    NavigationLink(destination: seeAll) {
                        Text("See all \(total)").textStyle(.sansXs, tone: .accent, numeric: true)
                    }
                    .buttonStyle(AppPressableButtonStyle())
                }
                .padding(.horizontal, DS.Spacing.sectionInset)
                RecipeShelf("", recipes: recipes) { RecipeDetailView(recipe: $0) }
            }
        }
    }
}
