import SwiftUI

/// One answer from the review screen, on its own: the same control as its step,
/// bound to the shared draft, so closing the sheet shows the new value in the review.
/// A read-and-adjust sheet: close only, no commit (Save stays on the review screen).
struct RateAnswerSheet: View {
    let question: RateQuestion
    @Binding var answers: RatingAnswers
    let eyebrow: String

    var body: some View {
        NavigationStack {
            SheetBody {
                ScreenHeader(question.title, eyebrow: eyebrow, summary: question.summary)
                RateQuestionBody(question: question, answers: $answers)
            }
            .screenTitle(question.reviewTitle, displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: question == .tags ? [.large] : [.medium, .large])
    }
}
