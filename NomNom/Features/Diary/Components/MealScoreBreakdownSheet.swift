import SwiftUI

/// Modal sheet presenting detailed infographics on how the dinner party scored a meal,
/// along with historical scores from past occasions.
struct MealScoreBreakdownSheet: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store

    private var averageScore: Double? {
        store.averageScore(forMeal: meal.id)
    }

    private var averageReaction: Reaction? {
        store.averageReaction(forMeal: meal.id)
    }

    private var mealRatings: [MealRating] {
        store.ratings(forMeal: meal.id)
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sectionCompact) {
                    // 1. Hero Score Boxes
                    heroScoreSection

                    // 2. Consensus Distribution Infographic
                    MealRatingDistributionCard(ratings: mealRatings)

                    // 3. Member Breakdown
                    memberBreakdownSection

                    // 4. Historical Scores Infographic
                    MealHistoricalScoresCard(currentMeal: meal, history: history)
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Dinner Party Rating", displayMode: .inline)
            .sheetCancelToolbar()
            .presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var heroScoreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let score = averageScore, let reaction = averageReaction {
                DividedScoreCard(
                    score: String(format: "%.1f", score * 100),
                    verdict: reaction.shortLabel,
                    color: reaction.text,
                    trend: trend
                )
            } else {
                DividedScoreCard(
                    score: "—",
                    verdict: "Unrated",
                    color: DS.Color.textTertiary,
                    trend: trend
                )
            }

            // Hero narrative subtitle
            Text(narrativeSubtitle)
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.horizontal, 2)
        }
    }

    private var narrativeSubtitle: String {
        guard let score = averageScore else {
            return "No ratings have been submitted by the dinner party yet."
        }
        let formattedPercent = String(format: "%.1f", score * 100)
        let count = mealRatings.count
        let countText = "\(count) \(count == 1 ? "member" : "members")"

        if let trend, let delta = trend.delta, delta != 0 {
            let direction = delta > 0 ? "up \(delta) points" : "down \(abs(delta)) points"
            return "Scored \(formattedPercent)/100 across \(countText) (\(direction) compared to last time)."
        }
        return "Scored \(formattedPercent)/100 across \(countText)."
    }

    private var memberBreakdownSection: some View {
        let details = store.verdictDetails(forMeal: meal.id)

        return Group {
            if !details.isEmpty {
                SectionCard("Party Member Scores", caption: "\(details.count) submitted") {
                    VStack(spacing: 8) {
                        ForEach(details) { detail in
                            memberScoreRow(detail)

                            if detail.id != details.last?.id {
                                Divider().overlay(DS.Color.line.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }

    private func memberScoreRow(_ detail: FoodStore.VerdictDetail) -> some View {
        HStack(spacing: 12) {
            // Initial circle avatar (Strictly NO EMOJIS)
            ZStack {
                Circle()
                    .fill(DS.Color.panel)
                    .overlay {
                        Circle()
                            .strokeBorder(DS.Color.line.opacity(0.4), lineWidth: 0.5)
                    }
                Text(String(detail.name.prefix(1)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .frame(width: 32, height: 32)

            Text(detail.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            if let reaction = detail.reaction {
                let formattedPercent = String(format: "%.1f", reaction.score * 100)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formattedPercent)
                        .font(Font.newsreader(.subheadline, weight: .semibold))
                        .foregroundStyle(reaction.text)
                    Text("/100")
                        .font(Font.newsreader(.caption2, weight: .medium))
                        .foregroundStyle(reaction.text.opacity(0.6))
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.horizontal, 2)
                    Text(reaction.shortLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(reaction.text)
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
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
