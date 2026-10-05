import SwiftUI

/// "Remind to rate", opened from MealScoreCard's unrated state: a ScreenHeader, then a Card list of
/// everyone who hasn't rated, each a ListRow with Avatar `sm` and a Toggle (all on), and
/// a full-width "Remind" AppButton `lg` that asks or reminds every switched-on person.
/// Someone inside the one-a-day wait shows "Reminded 3 hr. ago" with the switch off and
/// disabled.
struct RemindRatersSheet: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []
    @State private var didSeed = false
    @State private var isSending = false
    @State private var error: String?

    var body: some View {
        let raters = store.remindableRaters(forMeal: meal)

        NavigationStack {
            SheetBody {
                ScreenHeader(
                    "Remind to rate",
                    eyebrow: store.dishName(forMeal: meal),
                    summary: "Each person gets a push, or a note in their inbox. One reminder a day."
                )
                Card(layout: .list) {
                    ForEach(raters) { rater in
                        if let profile = rater.profile {
                            row(rater, profile: profile)
                        }
                    }
                }
                AppButton(
                    selected.count > 1 ? "Remind \(selected.count) people" : "Remind",
                    size: .lg, fullWidth: true, isLoading: isSending
                ) { send() }
                .disabled(selected.isEmpty)
            }
            .screenTitle("Remind", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: [.medium, .large])
        .onAppear { seed(raters) }
        .alert("Couldn\u{2019}t send", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    private func row(_ rater: FoodStore.MealRater, profile: Profile) -> some View {
        let canNudge = store.canNudgeToRate(profile, onMeal: meal.id)
        return ListRow(
            store.firstName(for: rater.ref),
            meta: meta(for: profile),
            leading: .avatar(Avatar(
                name: store.label(for: rater.ref).name,
                photoPath: rater.photoPath,
                size: .sm,
                decorative: true
            )),
            trailing: .toggle(Binding(
                get: { selected.contains(profile.id) },
                set: { on in
                    if on { selected.insert(profile.id) } else { selected.remove(profile.id) }
                }
            ))
        )
        .disabled(!canNudge)
    }

    private func meta(for profile: Profile) -> String {
        switch store.ratingAskStatus(for: profile.id, onMeal: meal.id) {
        case .notAsked:
            return "Not asked yet"
        case .canRemind(let since), .waiting(let since, _, _):
            let verb = store.pendingInvite(for: profile.id, onMeal: meal.id)?.remindedAt == nil ? "Asked" : "Reminded"
            return "\(verb) \(since.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))"
        }
    }

    /// Every switch starts on, except for people still inside the one-a-day wait.
    private func seed(_ raters: [FoodStore.MealRater]) {
        guard !didSeed else { return }
        didSeed = true
        selected = Set(raters.compactMap(\.profile)
            .filter { store.canNudgeToRate($0, onMeal: meal.id) }
            .map(\.id))
    }

    private func send() {
        let profiles = store.remindableRaters(forMeal: meal)
            .compactMap(\.profile)
            .filter { selected.contains($0.id) }
        isSending = true
        Task {
            var failure: String?
            for profile in profiles {
                let ok = await store.nudgeToRate(profile, onMeal: meal.id)
                if !ok {
                    failure = failure ?? store.errorMessage
                    store.errorMessage = nil
                }
            }
            isSending = false
            if let failure { error = failure } else { dismiss() }
        }
    }
}
