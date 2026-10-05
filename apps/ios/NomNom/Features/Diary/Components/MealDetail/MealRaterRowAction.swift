import SwiftUI

/// The trailing control on an unrated "Who rated" row (a ListRow `AppButton sm` slot,
/// so the row splits: the title region opens the rater sheet, this sends the nudge).
///
/// - not asked → "Ask" (solid)
/// - can remind → "Remind" (solid)
/// - waiting → "Reminded" / "Asked" (soft, disabled; one reminder a day)
/// - just sent → "Sent" (soft) for two seconds
struct MealRaterRowAction: View {
    let meal: Meal
    let profile: Profile

    @Environment(FoodStore.self) private var store
    @State private var isSending = false
    @State private var justSent = false
    @State private var error: String?

    var body: some View {
        button
            .alert("Couldn\u{2019}t send", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
    }

    @ViewBuilder
    private var button: some View {
        if justSent {
            AppButton("Sent", variant: .secondary, appearance: .soft, size: .sm) {}
                .disabled(true)
        } else {
            switch store.ratingAskStatus(for: profile.id, onMeal: meal.id) {
            case .notAsked:
                AppButton("Ask", variant: .secondary, appearance: .soft, size: .sm, isLoading: isSending) { send(ask: true) }
            case .canRemind:
                AppButton("Remind", variant: .secondary, appearance: .soft, size: .sm, isLoading: isSending) { send(ask: false) }
            case .waiting(_, _, let reminded):
                AppButton(reminded ? "Reminded" : "Asked", variant: .secondary, appearance: .soft, size: .sm) {}
                    .disabled(true)
            }
        }
    }

    private func send(ask: Bool) {
        isSending = true
        Task {
            let ok: Bool
            if ask {
                ok = await store.askToRate(member: profile, forMeal: meal.id)
            } else if let invite = store.pendingInvite(for: profile.id, onMeal: meal.id) {
                ok = await store.remindToRate(invite: invite)
            } else {
                ok = false
            }
            isSending = false
            if ok {
                justSent = true
                try? await Task.sleep(for: .seconds(2))
                justSent = false
            } else {
                error = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}
