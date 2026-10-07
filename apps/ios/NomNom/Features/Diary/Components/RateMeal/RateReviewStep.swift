import SwiftUI

/// The last screen of the rate flow: every answer as a ListRow (tap one to change just
/// that answer in a small sheet) and the eater's own note. RateMealSheet puts Save
/// top-right (`.stepCommitToolbar`).
struct RateReviewStep: View {
    @Binding var answers: RatingAnswers
    let eyebrow: String

    @State private var editing: RateQuestion?

    @Environment(FoodStore.self) private var store

    var body: some View {
        SheetBody {
            ScreenHeader("Your rating", eyebrow: eyebrow, summary: "Tap an answer to change it.")
            Card(layout: .list) {
                ForEach(RateQuestion.allCases) { question in
                    ListRow(
                        question.reviewTitle,
                        meta: question.answer(in: answers, tagLabels: store.ratingTagLabels(answers.tags)),
                        trailingAction: ListRowIconAction(
                            icon: "pencil",
                            accessibilityLabel: "Change \(question.reviewTitle.lowercased())",
                            variant: .secondary
                        ) { editing = question },
                        chevron: false
                    ) {
                        editing = question
                    }
                }
            }
            SectionCard("Your note", trailing: "Optional") {
                NoteField("Anything else? Flavour notes, what you\u{2019}d change", text: $answers.note, title: "Your note")
            }
        }
        .screenTitle("Rate meal", displayMode: .inline)
        .sheet(item: $editing) { question in
            RateAnswerSheet(question: question, answers: $answers, eyebrow: eyebrow)
        }
    }
}
