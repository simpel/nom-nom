import SwiftUI

/// One recipe on the leaderboard: a ListRow with its rank numeral, PhotoCard thumbnail,
/// cuisine, effort and times cooked, its score and a chevron. Place it in a
/// `Card(layout: .list)` inside a NavigationLink.
struct RecipeLeaderboardRow: View {
    let rank: Int
    let recipe: Recipe
    let score: Double
    let reaction: Reaction

    @Environment(FoodStore.self) private var store

    private var meta: String {
        let cooked = store.servings(of: recipe.id).count
        return [
            Cuisine.formatDisplayName(recipe.cuisine),
            recipe.effort?.label,
            cooked > 0 ? "\(cooked)\u{00D7} cooked" : nil
        ]
        .compactMap { $0 }
        .joined(separator: " \u{00B7} ")
    }

    var body: some View {
        ListRow(
            recipe.name,
            meta: meta,
            leading: .rank(rank),
            trailing: .score(score),
            chevron: true
        )
    }
}

#Preview {
    NomNomPreview { store in
        Card(layout: .list) {
            ForEach(Array(store.myDishes.prefix(4).enumerated()), id: \.element.id) { index, recipe in
                RecipeLeaderboardRow(rank: index + 1, recipe: recipe, score: 0.8, reaction: .great)
            }
        }
        .padding(DS.Spacing.gutter)
    }
}
