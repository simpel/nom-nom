import SwiftUI

/// Elegant score card displaying the dinner party meal rating:
/// - Distinct boxes on a row with small design system radius
/// - Displays score as X/100 and qualitative verdict
/// - Displays a 3rd box with a trend icon if the party has eaten this recipe before
/// - Fully clickable across the entire area to open the score breakdown sheet
struct MealDetailAverageRatingCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var showScoreSheet = false

    private var averageScore: Double? {
        store.averageScore(forMeal: meal.id)
    }

    private var averageReaction: Reaction? {
        store.averageReaction(forMeal: meal.id)
    }

    private var history: [Meal] {
        let partyIDs = Set(store.parties(forMeal: meal.id).map(\.id))
        return store.servings(of: meal.recipeID).filter { past in
            guard past.id != meal.id else { return false }
            let pastParties = store.parties(forMeal: past.id)
            if !partyIDs.isEmpty {
                return !Set(pastParties.map(\.id)).isDisjoint(with: partyIDs)
            } else {
                return pastParties.isEmpty
            }
        }
        .sorted { $0.eatenOn > $1.eatenOn }
    }

    private var trend: ScoreTrend? {
        guard let currentScore = averageScore else { return nil }
        let currentPercent = currentScore * 100

        for past in history {
            if let pastScore = store.averageScore(forMeal: past.id) {
                let pastPercent = pastScore * 100
                let delta = Int((currentPercent - pastPercent).rounded())
                if delta > 0 {
                    return .up(delta: delta)
                } else if delta < 0 {
                    return .down(delta: delta)
                } else {
                    return .neutral(delta: 0)
                }
            }
        }
        return nil
    }

    var body: some View {
        Group {
            if let score = averageScore, let reaction = averageReaction {
                DividedScoreCard(
                    score: String(format: "%.1f", score * 100),
                    verdict: reaction.shortLabel,
                    color: reaction.text,
                    trend: trend,
                    action: {
                        showScoreSheet = true
                    }
                )
            } else {
                DividedScoreCard(
                    score: "—",
                    verdict: "Unrated",
                    color: DS.Color.textTertiary,
                    trend: trend,
                    action: {
                        showScoreSheet = true
                    }
                )
            }
        }
        .sheet(isPresented: $showScoreSheet) {
            MealScoreBreakdownSheet(meal: meal)
        }
    }
}
