import SwiftUI

/// How the table scored a meal, as a DS BottomSheet: SheetHero (the average and what
/// changed since last time), the reaction distribution, each rater's score, and how
/// this group scored the dish before.
struct MealScoreBreakdownSheet: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var selectedExplanation: MealExplanationTarget?

    private var ratings: [MealRating] { store.ratings(forMeal: meal.id) }

    var body: some View {
        let history = store.partyHistory(for: meal)
        let lead = leadText

        NavigationStack {
            SheetBody {
                SheetHero(score: store.averageScore(forMeal: meal.id), lead: lead.text, emphasis: lead.emphasis)
                MealRatingDistributionCard(ratings: ratings)
                memberScores
                MealHistoricalScoresCard(currentMeal: meal, history: history)
            }
            .screenTitle(store.dishName(forMeal: meal), displayMode: .inline)
            .sheetCloseToolbar()
            .sheet(item: $selectedExplanation) { target in
                MealRaterExplanationSheet(target: target)
            }
        }
        .dsSheet(detents: [.fraction(0.85), .large])
    }

    @ViewBuilder
    private var memberScores: some View {
        let details = store.verdictDetails(forMeal: meal.id)
        if !details.isEmpty {
            DSSection("Member scores", trailing: "\(details.count) submitted") {
                Card(layout: .list) {
                    ForEach(details) { detail in
                        let target = MealExplanationTarget(rater: detail.ref, name: detail.name, meal: meal, store: store)
                        MealMemberScoreRow(detail: detail, affinities: target?.affinities ?? []) {
                            selectedExplanation = target
                        }
                    }
                }
            }
        }
    }

    private var leadText: (text: String, emphasis: String?) {
        guard !ratings.isEmpty else {
            return ("No ratings have been submitted for this meal yet.", nil)
        }
        let party = store.partyDisplayName(forMeal: meal)
        let group = party == "You" ? "you" : party
        let count = ratings.count == 1 ? "1 rating" : "\(ratings.count) ratings"
        guard let change = store.scoreChange(forMeal: meal) else {
            return ("\(count) from \(group) on \(meal.eatenOn.formatted(date: .abbreviated, time: .omitted)).", nil)
        }
        if change.delta == 0 {
            return ("Level with the last time \(group) had it, across \(count).", nil)
        }
        let points = abs(change.delta) == 1 ? "1 point" : "\(abs(change.delta)) points"
        let emphasis = "\(points) \(change.delta > 0 ? "up" : "down")"
        return ("\(emphasis) on the last time \(group) had it, across \(count).", emphasis)
    }
}
