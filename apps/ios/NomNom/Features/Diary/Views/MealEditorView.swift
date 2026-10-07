import SwiftUI
import PhotosUI

/// Add or edit one meal: multiple photos, title (with existing dish matching), date, dinner party serving, notes.
struct MealEditorView: View {
    var mealID: UUID?
    var initialDate: Date?
    var prefilledDishID: UUID?
    var prefilledPartyID: UUID?

    @Environment(FoodStore.self) private var store

    /// The one meal draft, shared by both steps. Step 1 holds the recipe (name, linked
    /// dish, recipe draft), date and notes; the Details step binds to the same draft.
    @State private var session: FormSession<FoodStore.MealDraft>
    @State private var loadedRecipeDishID: UUID?

    @State private var showDishPickerSheet = false
    @State private var showRecipeEditorSheet = false
    @State private var showCreateRecipeSheet = false
    @State private var navigateToDetailsStep = false

    init(mealID: UUID? = nil, initialDate: Date? = nil, prefilledDishID: UUID? = nil, prefilledPartyID: UUID? = nil) {
        self.mealID = mealID
        self.initialDate = initialDate
        self.prefilledDishID = prefilledDishID
        self.prefilledPartyID = prefilledPartyID
        let draft = FoodStore.MealDraft(mealID: mealID, dishName: "", eatenOn: .now, notes: "", recipe: FoodStore.RecipeDraft())
        self._session = State(initialValue: FormSession(draft, kind: mealID == nil ? .create : .edit, isLoaded: false))
    }

    private var meal: Meal? { mealID.flatMap { store.meal($0) } }
    private var isEditing: Bool { mealID != nil }

    private var existingMatchedDish: Dish? {
        if let linkedDishID = session.form.linkedDishID, let dish = store.dish(linkedDishID) { return dish }
        let normalized = session.form.dishName.trimmedName.normalizedForMatching
        guard !normalized.isEmpty else { return nil }
        return store.myDishes.first { $0.normalizedName == normalized }
    }

    private var recipeDraft: Binding<FoodStore.RecipeDraft> {
        Binding(get: { session.form.recipe ?? FoodStore.RecipeDraft() }, set: { session.form.recipe = $0 })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MealEditorRecipeSection(
                        title: $session.form.dishName,
                        existingMatchedRecipe: existingMatchedDish,
                        isExistingRecipe: existingMatchedDish != nil,
                        onPickRecipe: { showDishPickerSheet = true },
                        onCreateRecipe: { showCreateRecipeSheet = true },
                        onEditRecipe: { showRecipeEditorSheet = true },
                        onRemoveRecipe: removeSelectedDish
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
                DishRecipeEditSheet(dishName: $session.form.dishName, recipeDraft: recipeDraft)
            }
            .sheet(isPresented: $showCreateRecipeSheet) {
                CreateRecipeSheet(initialName: session.form.dishName.trimmedName) { recipe in
                    select(recipe)
                }
            }
            .sheet(isPresented: $showDishPickerSheet) {
                RecipePickerSheet(
                    onSelectExistingRecipe: select,
                    onSelectNewRecipe: { name in
                        removeSelectedDish()
                        session.form.dishName = name
                    }
                )
            }
            .onAppear(perform: load)
            .onChange(of: session.form.linkedDishID) { _, _ in syncMatchedDishRecipe() }
            .onChange(of: session.form.dishName) { _, _ in syncMatchedDishRecipe() }
        }
        .editorSheet(session, errorTitle: "Couldn\u{2019}t save meal")
    }

    private func select(_ dish: Dish) {
        session.form.dishName = dish.name
        session.form.linkedDishID = dish.id
        loadRecipe(from: dish, into: &session.form)
    }

    private func removeSelectedDish() {
        session.form.dishName = ""
        session.form.linkedDishID = nil
        session.form.recipe = FoodStore.RecipeDraft()
        loadedRecipeDishID = nil
    }

    /// Saves the meal, linking it to the matching dish when none was picked.
    private func save(_ form: FoodStore.MealDraft) async throws {
        var draft = form
        draft.dishName = form.dishName.trimmedName
        draft.linkedDishID = form.linkedDishID ?? existingMatchedDish?.id
        let saved = await store.save(draft)
        try store.throwIfFailed(saved)
    }

    private func syncMatchedDishRecipe() {
        guard let dish = existingMatchedDish, dish.id != loadedRecipeDishID else { return }
        loadRecipe(from: dish, into: &session.form)
    }

    private func loadRecipe(from dish: Dish, into draft: inout FoodStore.MealDraft) {
        loadedRecipeDishID = dish.id
        draft.recipe = FoodStore.RecipeDraft(
            ingredients: dish.ingredients,
            instructions: dish.instructions,
            existingPhotoPaths: dish.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: dish.effort
        )
        if draft.effort == nil, let dishEffort = dish.effort {
            draft.effort = dishEffort
        }
    }

    /// The opening draft: the meal as saved, or a new one with its prefills.
    private func load() {
        guard !session.isLoaded else { return }
        var draft = session.form

        guard let meal else {
            if let initialDate { draft.eatenOn = initialDate }
            if let prefilledDishID, let dish = store.dish(prefilledDishID) {
                draft.dishName = dish.name
                draft.linkedDishID = dish.id
                loadRecipe(from: dish, into: &draft)
            }
            draft.servedParties = prefilledPartyID.map { [$0] } ?? store.myParties.first.map { [$0.id] } ?? []
            session.load(draft)
            return
        }

        let dish = store.dish(meal.dishID)
        draft.dishName = dish?.name ?? ""
        draft.linkedDishID = dish?.id
        draft.eatenOn = meal.eatenOn
        draft.notes = meal.notes
        draft.mealTitle = meal.title ?? ""
        draft.effort = meal.effort
        draft.repeatDesire = meal.repeatDesire
        draft.photos = FoodStore.PhotosDraft(existingPaths: meal.photoPaths)
        draft.servedParties = Set(store.parties(forMeal: meal.id).map(\.id))
        if let dish { loadRecipe(from: dish, into: &draft) }
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

