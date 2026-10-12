import SwiftUI

/// Rating a meal, for yourself only: one question per screen (taste, what stood out,
/// how much you ate, want it again), then a review with your note and Save. Opened
/// only from the meal page, and only when `store.canRate(meal:)`. A previous rating
/// prefills every answer.
struct RateMealSheet: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store

    @State private var session = FormSession(RatingAnswers(), isLoaded: false)
    @State private var path: [RateStep] = []

    private var eyebrow: String {
        store.meal(mealID).map { store.dishName(forMeal: $0) } ?? "Meal"
    }

    var body: some View {
        NavigationStack(path: $path) {
            RateStepView(question: .taste, answers: $session.form, eyebrow: eyebrow) {
                go(to: RateQuestion.taste.next)
            }
            .sheetNextToolbar(session, canProceed: session.form.reaction != nil) {
                go(to: RateQuestion.taste.next)
            }
            .navigationDestination(for: RateStep.self) { step in
                destination(for: step)
            }
        }
        .environment(\.ratingTraits, traits)
        .editorSheet(session, errorTitle: "Couldn\u{2019}t save rating")
        .onAppear { session.load(RatingAnswers(store.rating(for: .account(store.userID), on: mealID))) }
        .onChange(of: session.form.reaction) { old, reaction in
            // From no verdict there are no tags to drop, only loaded ones to keep.
            if old != nil { dropTagsNotOffered(for: reaction) }
        }
    }

    private var traits: Set<String> { store.ratingTraits(forMeal: mealID) }

    /// Each verdict has its own tags: changing it keeps only the ones still offered.
    private func dropTagsNotOffered(for reaction: Reaction?) {
        let offered = reaction.map { Set(store.ratingTagOptions(for: $0, traits: traits).map(\.id)) } ?? []
        session.form.tags.formIntersection(offered)
    }

    @ViewBuilder
    private func destination(for step: RateStep) -> some View {
        switch step {
        case .question(let question):
            RateStepView(question: question, answers: $session.form, eyebrow: eyebrow) {
                go(to: question.next)
            }
            .stepNextToolbar { go(to: question.next) }
        case .review:
            RateReviewStep(answers: $session.form, eyebrow: eyebrow)
                .stepCommitToolbar(session) { answers in
                    let saved = await store.saveMyRating(mealID: mealID, answers: answers)
                    try store.throwIfFailed(saved)
                }
        }
    }

    /// Pushes a step once: an auto-advance and a tap on Next can land together.
    private func go(to step: RateStep) {
        guard !path.contains(step) else { return }
        path.append(step)
    }
}

#Preview {
    NomNomPreview { store in
        if let meal = store.meals.first {
            RateMealSheet(mealID: meal.id)
        }
    }
}
