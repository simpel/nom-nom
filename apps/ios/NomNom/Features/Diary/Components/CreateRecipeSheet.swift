import SwiftUI

/// Dedicated modal sheet for creating a new recipe with name, instructions, effort, and cuisine.
struct CreateRecipeSheet: View {
    var initialName: String = ""
    var initialCuisine: String? = nil
    var onCreated: ((Recipe) -> Void)?

    @State private var session: FormSession<RecipeForm>
    @State private var navigateToDetails = false
    @State private var showingScanner = false

    init(initialName: String = "", initialCuisine: String? = nil, onCreated: ((Recipe) -> Void)? = nil) {
        self.initialName = initialName
        self.initialCuisine = initialCuisine
        self.onCreated = onCreated
        let form = RecipeForm(name: initialName, cuisine: initialCuisine)
        self._session = State(initialValue: FormSession(form, kind: .create))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    AppButton(
                        "Scan Photos or Cookbook",
                        icon: "camera.viewfinder",
                        variant: .primary,
                        appearance: .outline,
                        fullWidth: true
                    ) {
                        showingScanner = true
                    }

                    RecipeBasicsForm(
                        name: $session.form.name,
                        coverPhotos: $session.form.coverPhotos,
                        effort: $session.form.recipe.effort,
                        cuisine: $session.form.recipe.cuisine
                    )
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle("New Recipe", displayMode: .inline)
            .sheetNextToolbar(session, canProceed: session.form.isValid) {
                navigateToDetails = true
            }
            .navigationDestination(isPresented: $navigateToDetails) {
                RecipeDetailsStepView(session: session, onCreated: onCreated)
            }
            .sheet(isPresented: $showingScanner) {
                RecipeScannerSheet { result, photoDataList in
                    applyParsedRecipe(result, photos: photoDataList)
                }
            }
        }
        .editorSheet(session, errorTitle: "Couldn\u{2019}t save recipe")
    }

    private func applyParsedRecipe(_ result: ParsedRecipeResult, photos: [Data]) {
        if !result.name.isEmpty {
            session.form.name = result.name
        }
        if let cuisine = result.cuisine {
            session.form.recipe.cuisine = cuisine
        }
        if let cuisineID = result.cuisineID {
            session.form.recipe.cuisineID = cuisineID
        }
        if let cookingMethodID = result.cookingMethodID {
            session.form.recipe.cookingMethodID = cookingMethodID
        }
        if let dishKindID = result.dishKindID {
            session.form.recipe.dishKindID = dishKindID
        }
        if let effort = result.effort, let level = EffortLevel(rawValue: effort) {
            session.form.recipe.effort = level
        }
        if let serves = result.serves {
            session.form.recipe.serves = serves
        }
        session.form.recipe.ingredients = result.ingredients
        session.form.recipe.instructions = result.instructions

        // Attach scanned photos to drafts
        for photo in photos {
            session.form.recipe.addPhotoData(photo)
        }

        navigateToDetails = true
    }
}
