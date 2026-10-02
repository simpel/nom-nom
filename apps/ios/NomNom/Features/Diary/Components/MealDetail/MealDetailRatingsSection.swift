import SwiftUI

/// Meal Detail's RatingList: everyone who could rate the meal, each with their change
/// vs their usual and their score; the viewer last. Unrated rows carry Rate / Ask to
/// rate / Asked; tapping a row opens why they scored it that way.
struct MealDetailRatingsSection: View {
    let meal: Meal
    let onRate: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var invitingMemberID: UUID?
    @State private var askError: String?
    @State private var explanation: MealExplanationTarget?

    var body: some View {
        let entries = store.raters(forMeal: meal).map(entry(for:))

        RatingList(entries: entries, total: entries.count, showsAvatars: true)
            .sheet(item: $explanation) { target in
                MealRaterExplanationSheet(target: target)
            }
            .alert("Couldn't Send", isPresented: Binding(
                get: { askError != nil },
                set: { if !$0 { askError = nil } }
            )) {
                Button("OK") { askError = nil }
            } message: {
                Text(askError ?? "")
            }
    }

    private func entry(for rater: FoodStore.MealRater) -> RatingListEntry {
        let score = rater.rating?.reaction.score
        let usual = store.usualScore(for: rater.ref, excluding: meal.id)
        let target = MealExplanationTarget(rater: rater.ref, name: store.firstName(for: rater.ref), meal: meal, store: store)

        return RatingListEntry(
            id: rater.id,
            name: rater.name,
            role: rater.ref == .account(meal.createdBy) ? "chef" : nil,
            score: score,
            delta: store.changeVsUsual(for: rater.ref, on: meal.id),
            isNew: score != nil && usual == nil,
            isViewer: rater.isViewer,
            photoPath: rater.photoPath,
            action: score == nil ? action(for: rater) : nil,
            onTap: tapAction(for: rater, target: target)
        )
    }

    private func action(for rater: FoodStore.MealRater) -> RatingListAction? {
        if rater.isViewer { return .rate(onRate) }
        if rater.isAsked { return .asked }
        guard let profile = rater.profile else { return nil }
        return .ask(isLoading: invitingMemberID == profile.id) { askToRate(profile) }
    }

    private func tapAction(for rater: FoodStore.MealRater, target: MealExplanationTarget?) -> (() -> Void)? {
        if rater.rating != nil, let target {
            return { explanation = target }
        }
        return rater.isViewer ? onRate : nil
    }

    private func askToRate(_ member: Profile) {
        invitingMemberID = member.id
        Task {
            let ok = await store.askToRate(member: member, forMeal: meal.id)
            invitingMemberID = nil
            if !ok {
                askError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}
