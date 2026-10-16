import SwiftUI
import PhotosUI

/// Add or edit one meal: multiple photos, title (with existing recipe matching), date, dinner party serving, notes.
struct MealEditorView: View {
    var mealID: UUID?
    var initialDate: Date?
    var prefilledRecipeID: UUID?
    var prefilledPartyID: UUID?

    @Environment(FoodStore.self) private var store

    /// The one meal draft, shared by both steps. Step 1 holds the recipe (name, linked
    /// recipe, recipe draft), date and notes; the Details step binds to the same draft.
    @State private var session: FormSession<FoodStore.MealDraft>
    @State private var loadedRecipeID: UUID?

    @State private var showRecipePickerSheet = false
    @State private var showRecipeEditorSheet = false
    @State private var showCreateRecipeSheet = false
    @State private var navigateToDetailsStep = false

    init(mealID: UUID? = nil, initialDate: Date? = nil, prefilledRecipeID: UUID? = nil, prefilledPartyID: UUID? = nil) {
        self.mealID = mealID
        self.initialDate = initialDate
        self.prefilledRecipeID = prefilledRecipeID
        self.prefilledPartyID = prefilledPartyID
        let draft = FoodStore.MealDraft(mealID: mealID, recipeName: "", eatenOn: .now, notes: "", recipe: FoodStore.RecipeDraft())
        self._session = State(initialValue: FormSession(draft, kind: mealID == nil ? .create : .edit, isLoaded: false))
    }

    private var meal: Meal? { mealID.flatMap { store.meal($0) } }
    private var isEditing: Bool { mealID != nil }

    private var existingMatchedRecipe: Recipe? {
        if let linkedRecipeID = session.form.linkedRecipeID, let recipe = store.recipe(linkedRecipeID) { return recipe }
        let normalized = session.form.recipeName.trimmedName.normalizedForMatching
        guard !normalized.isEmpty else { return nil }
        return store.myRecipes.first { $0.normalizedName == normalized }
    }

    private var recipeDraft: Binding<FoodStore.RecipeDraft> {
        Binding(get: { session.form.recipe ?? FoodStore.RecipeDraft() }, set: { session.form.recipe = $0 })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MealEditorRecipeSection(
                        title: $session.form.recipeName,
                        existingMatchedRecipe: existingMatchedRecipe,
                        isExistingRecipe: existingMatchedRecipe != nil,
                        onPickRecipe: { showRecipePickerSheet = true },
                        onCreateRecipe: { showCreateRecipeSheet = true },
                        onEditRecipe: { showRecipeEditorSheet = true },
                        onRemoveRecipe: removeSelectedRecipe
                    )

                    MealEditorDetailsSection(date: $session.form.eatenOn, notes: $session.form.notes)
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle(isEditing ? "Edit meal" : "New meal", displayMode: .inline)
            .sheetNextToolbar(session, canProceed: session.form.isValid) { navigateToDetailsStep = true }
            .navigationDestination(isPresented: $navigateToDetailsStep) {
                MealDetailsStepView(draft: $session.form)
                    .stepCommitToolbar(session, save: save)
            }
            .sheet(isPresented: $showRecipeEditorSheet) {
                MealRecipeEditSheet(recipeName: $session.form.recipeName, recipeDraft: recipeDraft)
            }
            .sheet(isPresented: $showCreateRecipeSheet) {
                CreateRecipeSheet(initialName: session.form.recipeName.trimmedName) { recipe in
                    select(recipe)
                }
            }
            .sheet(isPresented: $showRecipePickerSheet) {
                RecipePickerSheet(
                    onSelectExistingRecipe: select,
                    onSelectNewRecipe: { name in
                        removeSelectedRecipe()
                        session.form.recipeName = name
                    }
                )
            }
            .onAppear(perform: load)
            .onChange(of: session.form.linkedRecipeID) { _, _ in syncMatchedRecipe() }
            .onChange(of: session.form.recipeName) { _, _ in syncMatchedRecipe() }
        }
        .editorSheet(session, errorTitle: "Couldn\u{2019}t save meal")
    }

    private func select(_ recipe: Recipe) {
        session.form.recipeName = recipe.name
        session.form.linkedRecipeID = recipe.id
        loadRecipe(from: recipe, into: &session.form)
    }

    private func removeSelectedRecipe() {
        session.form.recipeName = ""
        session.form.linkedRecipeID = nil
        session.form.recipe = FoodStore.RecipeDraft()
        loadedRecipeID = nil
    }

    /// Saves the meal, linking it to the matching recipe when none was picked.
    private func save(_ form: FoodStore.MealDraft) async throws {
        var draft = form
        draft.recipeName = form.recipeName.trimmedName
        draft.linkedRecipeID = form.linkedRecipeID ?? existingMatchedRecipe?.id
        let saved = await store.save(draft)
        try store.throwIfFailed(saved)
    }

    private func syncMatchedRecipe() {
        guard let recipe = existingMatchedRecipe, recipe.id != loadedRecipeID else { return }
        loadRecipe(from: recipe, into: &session.form)
    }

    private func loadRecipe(from recipe: Recipe, into draft: inout FoodStore.MealDraft) {
        loadedRecipeID = recipe.id
        draft.recipe = FoodStore.RecipeDraft(
            ingredientGroups: recipe.ingredientGroups,
            instructions: recipe.instructions,
            existingPhotoPaths: recipe.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: recipe.effort
        )
        if draft.effort == nil, let recipeEffort = recipe.effort {
            draft.effort = recipeEffort
        }
    }

    /// The opening draft: the meal as saved, or a new one with its prefills.
    private func load() {
        guard !session.isLoaded else { return }
        var draft = session.form

        guard let meal else {
            if let initialDate { draft.eatenOn = initialDate }
            if let prefilledRecipeID, let recipe = store.recipe(prefilledRecipeID) {
                draft.recipeName = recipe.name
                draft.linkedRecipeID = recipe.id
                loadRecipe(from: recipe, into: &draft)
            }
            draft.servedParties = prefilledPartyID.map { [$0] } ?? store.myParties.first.map { [$0.id] } ?? []
            session.load(draft)
            return
        }

        let recipe = store.recipe(meal.recipeID)
        draft.recipeName = recipe?.name ?? ""
        draft.linkedRecipeID = recipe?.id
        draft.eatenOn = meal.eatenOn
        draft.notes = meal.notes
        draft.mealTitle = meal.title ?? ""
        draft.effort = meal.effort
        draft.repeatDesire = meal.repeatDesire
        draft.photos = FoodStore.PhotosDraft(existingPaths: meal.photoPaths)
        draft.servedParties = Set(store.parties(forMeal: meal.id).map(\.id))
        if let recipe { loadRecipe(from: recipe, into: &draft) }
        session.load(draft)
    }
}

#Preview("New Meal") {
    NomNomPreview {
        MealEditorView()
    }
}

#Preview("Edit Meal") {
    NomNomPreview { store in
        if let meal = store.meals.first {
            MealEditorView(mealID: meal.id)
        }
    }
}

