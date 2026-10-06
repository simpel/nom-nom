import SwiftUI

/// "Remind to rate", opened from MealScoreCard's unrated state and a Meals-list MealRow nobody
/// has rated yet. It opens just tall enough to show the Remind button: a ScreenHeader, then a Card list of
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
    /// The blocks' height and the bar + home-indicator insets, measured so the sheet
    /// opens just tall enough to show the Remind button.
    @State private var contentHeight: CGFloat = 0
    @State private var insets: CGFloat = 0
    @State private var detent: PresentationDetent = .medium

    /// SheetBody's `spacing-2` top and `spacing-10` bottom padding around the blocks.
    private var fitDetent: PresentationDetent {
        guard contentHeight > 0 else { return .medium }
        return .height(insets + DS.Spacing.s2 + contentHeight + DS.Spacing.s10)
    }

    var body: some View {
        let raters = store.remindableRaters(forMeal: meal)

        NavigationStack {
            SheetBody {
                VStack(alignment: .leading, spacing: DS.Spacing.s6) {
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
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } action: { insets = $0 }
            .screenTitle("Remind", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: [fitDetent, .large], selection: $detent)
        .onChange(of: fitDetent) { _, new in if detent != .large { detent = new } }
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
