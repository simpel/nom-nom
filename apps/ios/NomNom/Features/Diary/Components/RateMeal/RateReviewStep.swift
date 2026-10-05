import SwiftUI

/// The last screen of the rate flow: every answer as a ListRow (tap one to change just
/// that answer in a small sheet), the eater's own note, and Save top-right.
struct RateReviewStep: View {
    @Binding var answers: RatingAnswers
    let eyebrow: String
    let isSaving: Bool
    let onSave: () -> Void

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
        .stepCommitToolbar(isSaving: isSaving, canSave: answers.reaction != nil, onSave: onSave)
        .sheet(item: $editing) { question in
            RateAnswerSheet(question: question, answers: $answers, eyebrow: eyebrow)
        }
    }
}
