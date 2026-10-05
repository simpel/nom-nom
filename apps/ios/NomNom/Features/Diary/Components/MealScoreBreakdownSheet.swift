import SwiftUI

/// How the table scored a meal, as a DS BottomSheet ("Nom Nom iOS" score canvas, board 1):
/// SheetHero (the average and what changed since last time), the Pro "Why it landed at"
/// card, and each rater's score. The distribution and the dish's history live in the Pro
/// breakdown (`MealScoreInsightsSheet`).
struct MealScoreBreakdownSheet: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var selectedRater: MealRaterTarget?

    private var ratings: [MealRating] { store.ratings(forMeal: meal.id) }

    var body: some View {
        let lead = leadText

        NavigationStack {
            SheetBody {
                SheetHero(score: store.averageScore(forMeal: meal.id), lead: lead.text, emphasis: lead.emphasis)
                MealScoreInsightsCard(meal: meal)
                memberScores
            }
            .screenTitle(store.dishName(forMeal: meal), displayMode: .inline)
            .sheetCloseToolbar()
            .sheet(item: $selectedRater) { target in
                RaterScoreSheet(meal: meal, rater: target.ref)
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
                        MealMemberScoreRow(detail: detail, affinities: target.affinities) {
                            selectedRater = MealRaterTarget(ref: detail.ref, hasRated: true)
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
