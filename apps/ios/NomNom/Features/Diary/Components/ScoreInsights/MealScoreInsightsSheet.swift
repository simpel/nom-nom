import SwiftUI

/// The Pro breakdown of a meal's score, opened from `MealScoreInsightsCard` ("Nom Nom
/// iOS" score canvas, board 2). A ProView sheet: ProMark over a ScreenHeader naming what
/// most explains the score, then "Make it land next time" (AI tips, saved as the party's
/// note on the recipe), "What pulled it down" and "Past meals with this recipe".
struct MealScoreInsightsSheet: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var tweaks: RecipeTweaks?
    @State private var tweaksFailure: RecipeTweaksFailure?

    var body: some View {
        let points = store.averageScore(forMeal: meal.id).map { Int(($0 * 100).rounded()) }
        let reasons = store.tableExplanation(forMeal: meal)

        NavigationStack {
            ProGate("Score insights are part of Nom Nom Pro") {
                SheetBody {
                    VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                        ProMark()
                        ScreenHeader(headline(reasons), summary: summary(reasons))
                    }
                    if store.tweaksParty(forMeal: meal) != nil {
                        MealScoreTweaksSection(meal: meal, tweaks: tweaks, failure: tweaksFailure) {
                            await loadTweaks(force: true)
                        }
                    }
                    MealScoreReasonsSection(reasons: reasons)
                    RecipePastMealsSection(meal: meal)
                    Text(provenance)
                        .textStyle(.sansXs, tone: .tertiary)
                }
            }
            .screenTitle(points.map { "Why it scored \($0)" } ?? "Score insights", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(pro: true)
        .task { await loadTweaks(force: false) }
    }

    private func loadTweaks(force: Bool) async {
        guard store.tweaksParty(forMeal: meal) != nil else { return }
        // Back to "Working out what to change" while it runs, so a retry shows it is trying.
        tweaksFailure = nil
        tweaks = nil
        do {
            tweaks = try await store.recipeTweaks(forMeal: meal, force: force)
        } catch {
            tweaksFailure = error as? RecipeTweaksFailure ?? .unavailable
        }
    }

    /// The AI headline, else the top reason down, else a plain title.
    private func headline(_ reasons: [TableReason]) -> String {
        if let headline = tweaks?.headline, !headline.isEmpty { return headline }
        if let top = reasons.first(where: \.isNegative) { return "\(top.title) pulled it down" }
        return "How the table scored it"
    }

    private func summary(_ reasons: [TableReason]) -> String? {
        if let summary = tweaks?.summary, !summary.isEmpty { return summary }
        return reasons.first(where: \.isNegative)?.detail
    }

    private var provenance: String {
        let raters = store.ratings(forMeal: meal.id).count
        let servings = store.partyHistory(for: meal).count + 1
        let ratings = raters == 1 ? "1 rating" : "\(raters) ratings"
        let meals = servings == 1 ? "1 meal" : "\(servings) meals"
        return "Based on \(ratings) of this meal and \(meals) with this recipe."
    }
}
