import SwiftUI

/// Someone who hasn't rated a meal yet ("Nom Nom iOS" canvas, RaterUnrated): a
/// BottomSheet titled with their name, the PersonHeaderRow, an empty score (dashed
/// placeholder, ScoreValue `lg` em dash, empty Bar), "Oskar hasn’t rated Pasta alla
/// norma yet.", a status line, and the Ask / Remind button (RaterRemindButton).
struct RaterPendingSheet: View {
    let meal: Meal
    let rater: RaterRef

    @Environment(FoodStore.self) private var store
    @State private var showProfile = false
    @State private var justSent = false

    private var profile: Profile? {
        if case .account(let id) = rater { return store.profiles[id] }
        return nil
    }

    var body: some View {
        let name = store.firstName(for: rater)

        NavigationStack {
            SheetBody {
                RaterPersonRow(meal: meal, rater: rater) { showProfile = true }
                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    HStack(spacing: DS.Spacing.s3) {
                        EmptyScoreGlyph()
                        ScoreValue(score: nil, size: .lg)
                    }
                    Bar(value: nil, size: .md).accessibilityHidden(true)
                    Text("\(name) hasn\u{2019}t rated \(store.dishName(forMeal: meal)) yet.")
                        .textStyle(.sansMd, tone: .secondary)
                    if let line = statusLine(name: name) {
                        Text(line).textStyle(.sansSm, tone: .tertiary)
                    }
                }
                if let profile {
                    RaterRemindButton(meal: meal, profile: profile, name: name, justSent: $justSent)
                }
            }
            .screenTitle(name, displayMode: .inline)
            .sheetCloseToolbar()
            .navigationDestination(isPresented: $showProfile) {
                PersonDetailView(raterRef: rater)
            }
        }
        .dsSheet(detents: [.medium, .large])
    }

    private func statusLine(name: String) -> String? {
        guard let profile else { return "Household members\u{2019} verdicts are added by whoever logs the meal." }
        if justSent {
            return profile.notifyViaPush ? "Push notification sent to \(name)." : "Sent to \(name)\u{2019}s inbox."
        }
        switch store.ratingAskStatus(for: profile.id, onMeal: meal.id) {
        case .notAsked:
            return "Not asked yet."
        case .canRemind(let since):
            let verb = store.pendingInvite(for: profile.id, onMeal: meal.id)?.remindedAt == nil ? "Asked" : "Reminded"
            return "\(verb) \(since.formatted(.relative(presentation: .named)))."
        case .waiting(let since, _, let reminded):
            let when = since.formatted(.relative(presentation: .named))
            return reminded ? "Reminded \(when). One reminder per day." : "Asked \(when)."
        }
    }
}

/// The unrated score's placeholder: a `spacing-11` circle on `sunken` with a dashed
/// `border-thick` `line-control` ring (DS-GAPS.md, "Empty score").
private struct EmptyScoreGlyph: View {
    var body: some View {
        Circle()
            .fill(DS.Color.sunken)
            .overlay {
                Circle().strokeBorder(
                    DS.Color.lineControl,
                    style: StrokeStyle(lineWidth: DS.BorderWidth.thick, dash: [DS.Spacing.s1, DS.Spacing.s1])
                )
            }
            .frame(width: DS.Spacing.s11, height: DS.Spacing.s11)
            .accessibilityHidden(true)
    }
}
