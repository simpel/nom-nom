import SwiftUI

/// Rating a meal, for yourself only: one question per screen (taste, what stood out,
/// how much you ate, want it again), then a review with your note and Save. Opened
/// only from the meal page, and only when `store.canRate(meal:)`. A previous rating
/// prefills every answer.
struct RateMealSheet: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var answers = RatingAnswers()
    @State private var path: [RateStep] = []
    @State private var isSaving = false
    @State private var didLoad = false

    private var eyebrow: String {
        store.meal(mealID).map { store.dishName(forMeal: $0) } ?? "Meal"
    }

    var body: some View {
        NavigationStack(path: $path) {
            RateStepView(question: .taste, answers: $answers, eyebrow: eyebrow, isRoot: true) {
                go(to: RateQuestion.taste.next)
            }
            .navigationDestination(for: RateStep.self) { step in
                destination(for: step)
            }
        }
        .environment(\.ratingTraits, traits)
        .dsSheet()
        .onAppear(perform: load)
        .onChange(of: answers.reaction) { _, reaction in dropTagsNotOffered(for: reaction) }
    }

    private var traits: Set<String> { store.ratingTraits(forMeal: mealID) }

    /// Each verdict has its own tags: changing it keeps only the ones still offered.
    private func dropTagsNotOffered(for reaction: Reaction?) {
        let offered = reaction.map { Set(store.ratingTagOptions(for: $0, traits: traits).map(\.id)) } ?? []
        answers.tags.formIntersection(offered)
    }

    @ViewBuilder
    private func destination(for step: RateStep) -> some View {
        switch step {
        case .question(let question):
            RateStepView(question: question, answers: $answers, eyebrow: eyebrow, isRoot: false) {
                go(to: question.next)
            }
        case .review:
            RateReviewStep(answers: $answers, eyebrow: eyebrow, isSaving: isSaving, onSave: save)
        }
    }

    /// Pushes a step once: an auto-advance and a tap on Next can land together.
    private func go(to step: RateStep) {
        guard !path.contains(step) else { return }
        path.append(step)
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        answers = RatingAnswers(store.rating(for: .account(store.userID), on: mealID))
    }

    private func save() {
        isSaving = true
        Task {
            let ok = await store.saveMyRating(mealID: mealID, answers: answers)
            isSaving = false
            if ok {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let meal = store.meals.first {
            RateMealSheet(mealID: meal.id)
        }
    }
}
