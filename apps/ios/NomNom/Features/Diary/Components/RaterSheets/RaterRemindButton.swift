import SwiftUI

/// The unrated sheet's one action, a full-width AppButton `lg` that walks through:
///
/// - not asked → "Remind Oskar to rate the meal" (mail, solid; sends the first ask)
/// - can remind → "Remind Oskar to rate the meal" (bell, solid) → loading → "Reminder sent" (check, soft)
/// - waiting → "Reminded · try again in 21 h" / "Asked · remind in 21 h" (check, soft, disabled)
///
/// One reminder a day (`remind_meal_invite`). When the invitee has push off, a note
/// under the button says it lands in their inbox.
struct RaterRemindButton: View {
    let meal: Meal
    let profile: Profile
    let name: String
    @Binding var justSent: Bool

    @Environment(FoodStore.self) private var store
    @State private var isSending = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            button
            if !profile.notifyViaPush {
                Text("\(name) has notifications off. They\u{2019}ll see it in their inbox.")
                    .textStyle(.sansSm, tone: .tertiary, align: .center)
            }
        }
        .alert("Couldn\u{2019}t send", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    @ViewBuilder
    private var button: some View {
        if justSent {
            AppButton("Reminder sent", icon: "checkmark", appearance: .soft, size: .lg, fullWidth: true) {}
        } else {
            switch store.ratingAskStatus(for: profile.id, onMeal: meal.id) {
            case .notAsked:
                AppButton("Remind \(name) to rate the meal", icon: "envelope", size: .lg, fullWidth: true, isLoading: isSending) {
                    ask()
                }
            case .canRemind:
                AppButton(
                    isSending ? "Sending reminder" : "Remind \(name) to rate the meal",
                    icon: "bell", size: .lg, fullWidth: true, isLoading: isSending
                ) {
                    remind()
                }
            case .waiting(_, let next, let reminded):
                let hours = max(1, Int((next.timeIntervalSinceNow / 3600).rounded(.up)))
                AppButton(
                    reminded ? "Reminded \u{00B7} try again in \(hours) h" : "Asked \u{00B7} remind in \(hours) h",
                    icon: "checkmark", appearance: .soft, size: .lg, fullWidth: true
                ) {}
                .disabled(true)
            }
        }
    }

    private func ask() {
        isSending = true
        Task {
            let ok = await store.askToRate(member: profile, forMeal: meal.id)
            isSending = false
            if !ok { error = store.errorMessage; store.errorMessage = nil }
        }
    }

    private func remind() {
        guard let invite = store.pendingInvite(for: profile.id, onMeal: meal.id) else { return }
        isSending = true
        Task {
            let ok = await store.remindToRate(invite: invite)
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
