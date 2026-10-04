import SwiftUI

/// One person under Meal Detail's "Who rated": a pressable ListRow with Avatar `sm`
/// and their first name.
///
/// - Rated: meta "Chef", "You" or "First rating"; trailing the change vs their usual
///   (delta Badge, "As usual" tertiary, or a "New" Badge) beside ScoreValue `xs`.
/// - Not yet: meta "You", "Not asked yet", "Asked 2 days ago" or "Reminded 2 hr. ago".
struct MealRaterRow: View {
    let meal: Meal
    let rater: FoodStore.MealRater
    let action: () -> Void

    @Environment(FoodStore.self) private var store

    private var name: String { rater.isViewer ? "You" : store.firstName(for: rater.ref) }
    private var score: Double? { rater.rating?.score }
    private var isNew: Bool { score != nil && store.usualScore(for: rater.ref, excluding: meal.id) == nil }

    private var meta: String? {
        if score != nil {
            if rater.ref == .account(meal.createdBy) { return "Chef" }
            if rater.isViewer { return nil }
            return isNew ? "First rating" : nil
        }
        if rater.isViewer { return "Tap to rate" }
        guard let profile = rater.profile else { return nil }
        switch store.ratingAskStatus(for: profile.id, onMeal: meal.id) {
        case .notAsked:
            return "Not asked yet"
        case .canRemind(let since), .waiting(let since, _, _):
            let verb = store.pendingInvite(for: profile.id, onMeal: meal.id)?.remindedAt == nil ? "Asked" : "Reminded"
            return "\(verb) \(since.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))"
        }
    }

    var body: some View {
        ListRow(
            name,
            meta: meta,
            leading: .avatar(Avatar(
                name: store.label(for: rater.ref).name,
                photoPath: rater.photoPath,
                size: .sm,
                decorative: true
            )),
            trailing: score == nil ? nil : .view {
                HStack(spacing: DS.Spacing.s3) {
                    change
                    ScoreValue(score: score, size: .xs)
                }
            },
            chevron: score == nil,
            action: action
        )
    }

    @ViewBuilder
    private var change: some View {
        if isNew {
            Badge("New", variant: .secondary, size: .sm)
        } else if let delta = store.changeVsUsual(for: rater.ref, on: meal.id) {
            if delta == 0 {
                Text("As usual").textStyle(.sansSm, tone: .tertiary)
            } else {
                Badge.delta(delta, size: .sm)
            }
        }
    }
}
