import SwiftUI

/// Card where the current user records their own verdict on somebody else's meal.
struct MyVerdictCard: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false

    private var mine: Reaction? { store.myRating(forMeal: mealID) }

    var body: some View {
        SectionCard(
            title: mine == nil ? "How was it?" : "Your verdict",
            caption: mine?.name
        ) {
            VStack(alignment: .leading, spacing: 10) {
                TactileOptionPicker(selection: Binding(
                    get: { mine },
                    set: { newReaction in
                        guard let newReaction else { return }
                        submit(newReaction)
                    }
                ))

                HStack {
                    Text(mine == nil
                         ? "Whoever cooked it gets told what you thought."
                         : "Tap another to change your mind.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isSaving { ProgressView().controlSize(.small) }
                }
            }
        }
    }

    private func submit(_ reaction: Reaction) {
        isSaving = true
        Task {
            await store.rate(mealID: mealID, as: reaction)
            isSaving = false
        }
    }
}
