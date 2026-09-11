import SwiftUI

/// Modal sheet displaying the global leaderboard of recipes ranked by average meal rating score.
struct RecipeLeaderboardSheet: View {
    var highlightedRecipeID: UUID? = nil

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
        VStack(alignment: .leading, spacing: DS.Spacing.section) {
            SectionCard(
                "Ranked Dishes",
                caption: "\(rankedRecipes.count) \(rankedRecipes.count == 1 ? "dish" : "dishes")"
            ) {
                VStack(spacing: 0) {
                    ForEach(Array(rankedRecipes.enumerated()), id: \.element.recipe.id) { index, item in
                        NavigationLink(value: item.recipe) {
                            RecipeLeaderboardRow(
                                rank: index + 1,
                                recipe: item.recipe,
                                score: item.score,
                                reaction: item.reaction,
                                isHighlighted: item.recipe.id == highlightedRecipeID
                            )
                        }
                        .buttonStyle(.plain)

                        if index < rankedRecipes.count - 1 {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screenHorizontal)
        .padding(.top, DS.Spacing.screenTop)
        .padding(.bottom, DS.Spacing.screenBottom)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Ranked Dishes", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Cook and rate meals to rank your recipes on the leaderboard.")
        }
        .padding(.top, 40)
    }
}

#Preview {
    NomNomPreview {
        RecipeLeaderboardSheet()
    }
}
