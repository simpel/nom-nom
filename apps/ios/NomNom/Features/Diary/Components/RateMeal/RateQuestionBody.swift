import SwiftUI

/// The control for one rate question, bound to the shared draft. Used by the step
/// screens and by the single-answer sheet on the review screen.
struct RateQuestionBody: View {
    let question: RateQuestion
    @Binding var answers: RatingAnswers
    var onPick: (() -> Void)?

    @Environment(FoodStore.self) private var store
    @Environment(\.ratingTraits) private var traits

    var body: some View {
        switch question {
        case .taste: RateTasteGrid(selection: $answers.reaction, onPick: onPick)
        case .tags:
            RateTagsPicker(
                tags: $answers.tags,
                options: answers.reaction.map { store.ratingTagOptions(for: $0, traits: traits) } ?? []
            )
        case .plate: RatePlateGrid(selection: $answers.plate, onPick: onPick)
        case .again: RateAgainGrid(selection: $answers.again, onPick: onPick)
        }
    }
}
