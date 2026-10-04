import SwiftUI

/// One screen of the rate flow, one purpose: a ScreenHeader asking the question (the
/// dish as eyebrow) over its control. "Next" sits top-right; single-choice questions
/// also move on by themselves a beat after a pick. Optional questions get "Skip"
/// pinned to the bottom, which clears that answer and moves on. The first question
/// is the sheet's root, so it carries the close button instead of back.
struct RateStepView: View {
    let question: RateQuestion
    @Binding var answers: RatingAnswers
    let eyebrow: String
    let isRoot: Bool
    let onNext: () -> Void

    private var canProceed: Bool {
        question != .taste || answers.reaction != nil
    }

    var body: some View {
        SheetBody {
            ScreenHeader(question.title, eyebrow: eyebrow, summary: question.summary)
            RateQuestionBody(question: question, answers: $answers,
                             onPick: question.advancesOnPick ? advanceAfterPick : nil)
        }
        .safeAreaInset(edge: .bottom) {
            if question != .taste {
                AppButton("Skip", variant: .secondary, appearance: .ghost, fullWidth: true, action: skip)
                    .padding(.horizontal, DS.Spacing.s5)
                    .padding(.bottom, DS.Spacing.s2)
                    .background(DS.Color.sheet)
            }
        }
        .screenTitle("Rate meal", displayMode: .inline)
        .modifier(RateStepToolbar(isRoot: isRoot, canProceed: canProceed, onNext: onNext))
    }

    /// Lets the chosen tile show its colour before the next screen slides in.
    private func advanceAfterPick() {
        Task {
            try? await Task.sleep(for: .seconds(DS.Motion.durationLayout))
            onNext()
        }
    }

    private func skip() {
        switch question {
        case .taste: break
        case .tags: answers.tags = []
        case .plate: answers.plate = nil
        case .again: answers.again = nil
        }
        onNext()
    }
}

/// The root step closes the sheet (`.sheetNextToolbar`); pushed steps keep the back
/// button (`.stepNextToolbar`). Both put "Next" top-right.
private struct RateStepToolbar: ViewModifier {
    let isRoot: Bool
    let canProceed: Bool
    let onNext: () -> Void

    func body(content: Content) -> some View {
        if isRoot {
            content.sheetNextToolbar(canProceed: canProceed, onNext: onNext)
        } else {
            content.stepNextToolbar(canProceed: canProceed, onNext: onNext)
        }
    }
}
