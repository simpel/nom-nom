import SwiftUI

/// Dedicated modal sheet for editing an existing recipe with the multi-step recipe flow.
struct RecipeEditSheet: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store

    @State private var session = FormSession(RecipeForm(), isLoaded: false)
    @State private var navigateToDetails = false

    private var recipe: Recipe? { store.recipe(recipeID) }
    private var isOwner: Bool { recipe?.ownerID == store.userID }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    if recipe != nil {
                        if isOwner {
                            RecipeBasicsForm(
                                name: $session.form.name,
                                coverPhotos: $session.form.coverPhotos,
                                effort: $session.form.recipe.effort,
                                cuisine: $session.form.recipe.cuisine
                            )
                        } else {
                            EmptyState(
                                "Only the creator can edit this",
                                message: "Ask whoever added this recipe to change its details.",
                                layout: .screen
                            )
                        }
                    } else {
                        EmptyState("Recipe is gone", message: "It was deleted.", layout: .screen)
                    }
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle("Edit Recipe", displayMode: .inline)
            .sheetNextToolbar(session, canProceed: session.form.isValid && isOwner) {
                navigateToDetails = true
            }
            .navigationDestination(isPresented: $navigateToDetails) {
                RecipeDetailsStepView(recipeID: recipeID, session: session)
            }
            .onAppear {
                if let recipe { session.load(RecipeForm(recipe)) }
            }
        }
        .editorSheet(session, errorTitle: "Couldn\u{2019}t save recipe")
    }
}
