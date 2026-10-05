import SwiftUI

/// "Make it land next time" on the Pro score sheet: up to three AI changes with the lift
/// each should give, and "Save as a note for this party", which adds them to the party's
/// note on the recipe (`party_recipe_notes`). Shown only for a meal eaten with a party.
struct MealScoreTweaksSection: View {
    let meal: Meal
    let tweaks: RecipeTweaks?
    let failure: RecipeTweaksFailure?
    let retry: () async -> Void

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false
    @State private var saved = false
    @State private var showRecipe = false

    var body: some View {
        let party = store.tweaksParty(forMeal: meal)
        DSSection("Make it land next time", trailing: trailing) {
            if let failure {
                EmptyState(
                    failure.title,
                    message: failure.message,
                    action: failure == .nothingToGoOn ? nil : EmptyStateAction("Try again") { Task { await retry() } }
                )
            } else if let tweaks {
                if tweaks.tips.isEmpty {
                    EmptyState("Nothing to change", message: "The ratings don\u{2019}t point at a clear fix yet.")
                } else {
                    VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                        Card(layout: .list) {
                            ForEach(tweaks.tips) { tip in
                                ListRow(tip.title, meta: tip.reason, trailing: .badge(.delta(tip.lift)))
                            }
                        }
                        if let party { saveButton(tweaks, party: party) }
                    }
                }
            } else {
                // The AI takes seconds: bones in the tips' own shape, and what is happening.
                Skeleton(rows: 3, trailing: true, caption: "Working out what to change")
            }
        }
    }

    private var trailing: String? {
        guard let count = tweaks?.tips.count, count > 0 else { return nil }
        return count == 1 ? "1 change" : "\(count) changes"
    }

    /// Before saving: "Save as a note for this party". After: the note is on the recipe,
    /// so the button becomes "View note on recipe" and opens it in a sheet.
    private func saveButton(_ tweaks: RecipeTweaks, party: Party) -> some View {
        VStack(spacing: DS.Spacing.s2) {
            AppButton(
                saved ? "View note on recipe" : "Save as a note for this party",
                icon: saved ? "arrow.right" : nil,
                iconPosition: .end,
                variant: .pro,
                // `soft` is `pro-soft`, the sheet's own ground here, so it would vanish.
                appearance: .outline,
                fullWidth: true,
                isLoading: isSaving
            ) {
                if saved {
                    showRecipe = true
                } else {
                    Task { await save(tweaks, party: party) }
                }
            }
            Text(saved
                 ? "Saved to \(party.name)\u{2019}s note on the recipe."
                 : "Shows on the recipe whenever you cook it for \(party.name).")
                .textStyle(.sansSm, tone: .tertiary, align: .center)
                .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showRecipe) {
            NavigationStack {
                RecipeDetailView(recipeID: meal.recipeID, showCloseButton: true, focusPartyNote: true)
            }
        }
    }

    private func save(_ tweaks: RecipeTweaks, party: Party) async {
        guard !isSaving else { return }
        isSaving = true
        await store.loadPartyRecipeNotes(dishID: meal.dishID)
        saved = await store.appendTips(tweaks, toDish: meal.dishID, party: party.id)
        isSaving = false
    }
}
