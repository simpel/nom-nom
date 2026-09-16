import SwiftUI

/// Infographic card presenting historical scores when the dinner party had this meal before.
/// Displays lifetime average score, trend comparison, and chronological history rows.
struct MealHistoricalScoresCard: View {
    let currentMeal: Meal
    let history: [Meal]

    @Environment(FoodStore.self) private var store

    private var scoredPastMeals: [(meal: Meal, score: Double, reaction: Reaction)] {
        history.compactMap { past in
            guard let avg = store.averageScore(forMeal: past.id),
                  let reaction = store.averageReaction(forMeal: past.id) else {
                return nil
            }
            return (past, avg * 100, reaction)
        }
    }

    private var historicalAverageScore: Double? {
        guard !scoredPastMeals.isEmpty else { return nil }
        let total = scoredPastMeals.map(\.score).reduce(0, +)
        return total / Double(scoredPastMeals.count)
    }

    var body: some View {
        SectionCard(
            "Historical Scores",
            caption: history.isEmpty ? "First time" : "\(history.count) past \(history.count == 1 ? "time" : "times")"
        ) {
            if history.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("First time with this recipe")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("This is the first time your dinner party has logged this meal. Historical comparisons will appear on future occasions.")
                        .font(.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    // Summary row comparing current with historical average
                    if let historicalAverageScore {
                        historicalSummaryHeader(historicalAverage: historicalAverageScore)
                    }

                    // Chronological past servings
                    VStack(spacing: 8) {
                        ForEach(history.prefix(6)) { past in
                            pastMealRow(past)

                            if past.id != history.prefix(6).last?.id {
                                Divider().overlay(DS.Color.line.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }

    private func historicalSummaryHeader(historicalAverage: Double) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("HISTORICAL AVERAGE")
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", historicalAverage))
                        .font(Font.newsreader(.title3, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("/100")
                        .font(Font.newsreader(.caption, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Spacer()

            if let currentScore = store.averageScore(forMeal: currentMeal.id) {
                let currentPercent = currentScore * 100
                let delta = Int((currentPercent - historicalAverage).rounded())

                HStack(spacing: 4) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.bold))
                    Text(delta >= 0 ? "+\(delta) vs avg" : "\(delta) vs avg")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(delta >= 0 ? DS.Color.Pine.pine600 : Color("ds/reaction/bad/text"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(delta >= 0 ? DS.Color.Pine.pine50 : Color("ds/reaction/bad/fill"))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func pastMealRow(_ past: Meal) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(past.eatenOn, format: .dateTime.day().month(.abbreviated).year())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Text(past.createdBy == store.userID ? "Cooked by you" : "Cooked by \(store.label(for: .account(past.createdBy)).name)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            if let score = store.averageScore(forMeal: past.id),
               let reaction = store.averageReaction(forMeal: past.id) {
                let formattedPercent = String(format: "%.1f", score * 100)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formattedPercent)
                        .font(Font.newsreader(.subheadline, weight: .semibold))
                        .foregroundStyle(reaction.text)
                    Text("/100")
                        .font(Font.newsreader(.caption2, weight: .medium))
                        .foregroundStyle(reaction.text.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(DS.Color.panel)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .strokeBorder(DS.Color.line.opacity(0.3), lineWidth: 0.5)
                        }
                }
            } else {
                Text("Unrated")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
