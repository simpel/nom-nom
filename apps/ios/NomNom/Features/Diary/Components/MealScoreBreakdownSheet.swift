import SwiftUI

/// Modal sheet presenting detailed infographics on how members scored this specific meal,
/// individual score analysis (dish kind, ingredients, baseline), and historical comparisons.
struct MealScoreBreakdownSheet: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var selectedExplanation: ExplanationTarget?

    private struct ExplanationTarget: Identifiable {
        let id = UUID()
        let raterName: String
        let affinities: [RaterTagAffinity]
    }

    private var averageScore: Double? {
        store.averageScore(forMeal: meal.id)
    }

    private var averageReaction: Reaction? {
        store.averageReaction(forMeal: meal.id)
    }

    private var mealRatings: [MealRating] {
        store.ratings(forMeal: meal.id)
    }

    private var dishName: String {
        store.dishName(forMeal: meal)
    }

    private var partyName: String {
        let parties = store.parties(forMeal: meal.id)
        if !parties.isEmpty {
            return parties.map(\.name).joined(separator: " & ")
        } else if let current = store.currentParty {
            return current.name
        }
        return "You"
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

                    // 3. Member Breakdown with Taste Insights
                    memberBreakdownSection

                    // 4. Historical Scores Infographic
                    MealHistoricalScoresCard(currentMeal: meal, history: history)
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("\(dishName) Rating", displayMode: .inline)
            .sheetCancelToolbar()
            .presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
            .sheet(item: $selectedExplanation) { target in
                MealRaterExplanationSheet(raterName: target.raterName, affinities: target.affinities)
            }
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
            return "No ratings have been submitted for this meal yet."
        }
        let formattedPercent = String(format: "%.1f", score * 100)
        let count = mealRatings.count
        let countText = "\(count) \(count == 1 ? "member" : "members")"
        let dateText = meal.eatenOn.formatted(date: .abbreviated, time: .omitted)

        if let trend, let delta = trend.delta, delta != 0 {
            let direction = delta > 0 ? "up \(delta) points" : "down \(abs(delta)) points"
            return "\(partyName) scored \(formattedPercent)/100 on \(dateText) (\(direction) vs last time)."
        }
        return "\(partyName) scored \(formattedPercent)/100 across \(countText) on \(dateText)."
    }

    private var memberBreakdownSection: some View {
        let details = store.verdictDetails(forMeal: meal.id)

        return Group {
            if !details.isEmpty {
                SectionCard("Member Scores", caption: "\(details.count) submitted") {
                    VStack(spacing: 8) {
                        ForEach(details) { detail in
                            let affinities = store.raterExplanation(for: detail.ref, meal: meal)
                            MealMemberScoreRow(
                                detail: detail,
                                affinities: affinities,
                                onTapExplain: {
                                    selectedExplanation = ExplanationTarget(raterName: detail.name, affinities: affinities)
                                }
                            )

                            if detail.id != details.last?.id {
                                Divider().overlay(DS.Color.line.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
}
