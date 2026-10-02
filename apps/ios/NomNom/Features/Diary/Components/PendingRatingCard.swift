import SwiftUI

/// A meal somebody else cooked, with rating buttons right there: a navigating ListRow
/// (PhotoCard `xs`, dish name, cook · date, a `secondary ghost` decline ✕) over a
/// TasteScoreSelector that rates on tap. Place it in a `Card(layout: .list)`.
struct PendingRatingCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false
    @State private var showDetail = false

    private var meta: String {
        let cook = store.label(for: .account(meal.createdBy)).name
        let date = meal.eatenOn.formatted(.dateTime.day().month(.abbreviated))
        return [cook, date].filter { !$0.isEmpty }.joined(separator: " \u{00B7} ")
    }

    private var selection: Binding<Reaction?> {
        Binding(get: { nil }, set: { reaction in
            if let reaction { rate(reaction) }
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListRow(
                store.dishName(forMeal: meal),
                meta: meta,
                leading: .photo(.meal(meal)),
                trailingAction: ListRowIconAction(
                    icon: "xmark",
                    accessibilityLabel: "Decline",
                    variant: .secondary,
                    isLoading: isSaving,
                    perform: decline
                ),
                chevron: true,
                action: { showDetail = true }
            )

            // Six `spacing-12` steps need 328pt; on narrower cards the row scrolls.
            ViewThatFits(in: .horizontal) {
                selector
                ScrollView(.horizontal, showsIndicators: false) { selector }
            }
            .padding(.bottom, DS.Spacing.s3)
            .disabled(isSaving)
            .opacity(isSaving ? DS.Opacity.disabled : DS.Opacity.o100)
        }
        .navigationDestination(isPresented: $showDetail) {
            MealDetailView(mealID: meal.id)
        }
    }

    private var selector: some View {
        TasteScoreSelector(selection: selection, label: "Rate \(store.dishName(forMeal: meal))", showVerdict: false)
    }

    private func rate(_ reaction: Reaction) {
        isSaving = true
        Task {
            await store.rate(mealID: meal.id, as: reaction)
            isSaving = false
        }
    }

    private func decline() {
        guard let invite = store.invites(forMeal: meal.id).first(where: { $0.inviteeID == store.userID }) else { return }
        isSaving = true
        Task {
            await store.decline(invite: invite)
            isSaving = false
        }
    }
}
