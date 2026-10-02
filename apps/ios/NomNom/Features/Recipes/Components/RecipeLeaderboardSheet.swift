import SwiftUI

/// Modal sheet displaying the global leaderboard of recipes ranked by average meal rating score.
struct RecipeLeaderboardSheet: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var rankedRecipes: [(recipe: Recipe, score: Double, reaction: Reaction)] {
        store.myDishes.compactMap { recipe in
            if let score = store.averageScore(forDish: recipe.id),
               let reaction = store.averageReaction(forDish: recipe.id) {
                return (recipe, score, reaction)
            }
            return nil
        }
        .sorted { $0.score > $1.score }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if rankedRecipes.isEmpty {
                    emptyState
                } else {
                    rankedList
                }
            }
            .background(DS.Color.bg)
            .screenTitle("Global Leaderboard", displayMode: .inline)
            .sheetCloseToolbar(color: DS.Color.textPrimary)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }

    // MARK: - Subviews

    private var rankedList: some View {
        DSSection(
            "Ranked Dishes",
            trailing: "\(rankedRecipes.count) \(rankedRecipes.count == 1 ? "dish" : "dishes")"
        ) {
            Card(layout: .list) {
                ForEach(Array(rankedRecipes.enumerated()), id: \.element.recipe.id) { index, item in
                    NavigationLink(value: item.recipe) {
                        RecipeLeaderboardRow(
                            rank: index + 1,
                            recipe: item.recipe,
                            score: item.score,
                            reaction: item.reaction
                        )
                    }
                    .buttonStyle(ListRowButtonStyle())
                }
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.s5)
        .padding(.bottom, DS.Spacing.s11)
    }

    private var emptyState: some View {
        // README case "Not enough data yet": no action, waiting is the answer.
        EmptyState(
            "Not enough meals yet",
            message: "Rate a meal and its recipe takes a place on the leaderboard.",
            layout: .screen
        )
        .padding(.horizontal, DS.Spacing.gutter)
    }
}

#Preview {
    NomNomPreview {
        RecipeLeaderboardSheet()
    }
}
