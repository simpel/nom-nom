import SwiftUI

/// One person's score for a meal ("Nom Nom iOS" canvas, RaterRated): a BottomSheet
/// titled "{name}’s score" with the PersonHeaderRow, their ScoreValue `lg` over a Bar
/// `md` and "8 above Anna’s usual of 84", the cook's note when they cooked it, and a
/// ProCard explaining the score from their history.
struct RaterScoreSheet: View {
    let meal: Meal
    let rater: RaterRef

    @Environment(FoodStore.self) private var store
    @State private var showProfile = false

    var body: some View {
        let isViewer = rater == .account(store.userID)
        let name = isViewer ? "You" : store.firstName(for: rater)
        let target = MealExplanationTarget(rater: rater, name: name, meal: meal, store: store)

        NavigationStack {
            SheetBody {
                RaterPersonRow(meal: meal, rater: rater) { showProfile = true }
                SheetHero(score: target.score, lead: target.lead.text, emphasis: target.lead.emphasis)
                if let note = cooksNote {
                    SectionCard("\(target.possessive) note on this meal", uppercase: false, quote: note)
                }
                if !target.affinities.isEmpty {
                    ProCard(
                        "Why \(isViewer ? "you" : name) scored it this way",
                        sub: target.provenance,
                        teaser: "See what in \(isViewer ? "your" : target.possessive) history explains this score: dish kinds, ingredients, cuisines and who cooked."
                    ) {
                        ReasonList(reasons: target.reasons())
                    }
                }
            }
            .screenTitle("\(target.possessive) score", displayMode: .inline)
            .sheetCloseToolbar()
            .navigationDestination(isPresented: $showProfile) {
                PersonDetailView(raterRef: rater)
            }
        }
        .dsSheet(detents: [.medium, .large])
    }

    /// The meal's note belongs to the cook, so it shows on the cook's sheet only.
    private var cooksNote: String? {
        guard let createdBy = meal.createdBy, rater == .account(createdBy) else { return nil }
        let text = meal.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
