import SwiftUI
import PhotosUI

/// Add or edit one meal: multiple photos, title (with existing dish matching), date, dinner party serving, notes.
struct MealEditorView: View {
    var mealID: UUID?
    var initialDate: Date?
    var prefilledDishID: UUID?
    var prefilledPartyID: UUID?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var linkedDishID: UUID?
    /// The one meal draft. Step 1 edits date and notes in place; the Details step
    /// binds to it directly, so typing there touches one field and nothing else.
    @State private var draft = FoodStore.MealDraft(dishName: "", eatenOn: .now, notes: "")

    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var loadedRecipeDishID: UUID?

    @State private var didLoad = false

    @State private var showDishPickerSheet = false
    @State private var showRecipeEditorSheet = false
    @State private var showCreateRecipeSheet = false
    @State private var navigateToDetailsStep = false

    private var meal: Meal? { mealID.flatMap { store.meal($0) } }
    private var isEditing: Bool { mealID != nil }
    private var canProceed: Bool { !title.trimmedName.isEmpty }

    private var existingMatchedDish: Dish? {
        if let linkedDishID, let dish = store.dish(linkedDishID) { return dish }
        let normalized = title.trimmedName.normalizedForMatching
        guard !normalized.isEmpty else { return nil }
        return store.myDishes.first { $0.normalizedName == normalized }
    }

    private var isExistingDish: Bool { existingMatchedDish != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MealEditorRecipeSection(
                        title: $title,
                        existingMatchedRecipe: existingMatchedDish,
                        isExistingRecipe: isExistingDish,
                        onPickRecipe: { showDishPickerSheet = true },
                        onCreateRecipe: { showCreateRecipeSheet = true },
                        onEditRecipe: { showRecipeEditorSheet = true },
                        onRemoveRecipe: removeSelectedDish
                    )

                    MealEditorDetailsSection(date: $draft.eatenOn, notes: $draft.notes)
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle(isEditing ? "Edit meal" : "New meal", displayMode: .inline)
            .sheetNextToolbar(canProceed: canProceed, onNext: proceed)
            .navigationDestination(isPresented: $navigateToDetailsStep) {
                MealDetailsStepView(draft: $draft, onDismiss: { dismiss() })
            }
            .sheet(isPresented: $showRecipeEditorSheet) {
                DishRecipeEditSheet(dishName: $title,
                                    recipeDraft: $recipeDraft)
            }
            .sheet(isPresented: $showCreateRecipeSheet) {
                CreateRecipeSheet(initialName: title.trimmedName) { recipe in
                    title = recipe.name
                    linkedDishID = recipe.id
                    loadRecipe(from: recipe)
                }
            }
            .sheet(isPresented: $showDishPickerSheet) {
                RecipePickerSheet(
                    onSelectExistingRecipe: { recipe in
                        title = recipe.name
                        linkedDishID = recipe.id
                        loadRecipe(from: recipe)
                    },
                    onSelectNewRecipe: { name in
                        title = name
                        linkedDishID = nil
                        loadedRecipeDishID = nil
                        recipeDraft = FoodStore.RecipeDraft()
                    }
                )
            }
            .onAppear(perform: loadIfNeeded)
            .onChange(of: linkedDishID) { _, _ in syncMatchedDishRecipe() }
            .onChange(of: title) { _, _ in syncMatchedDishRecipe() }
            .alert("Couldn't save meal",
                   isPresented: Binding(get: { store.errorMessage != nil },
                                        set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
        .dsSheet()
    }

    private func removeSelectedDish() {
        title = ""
        linkedDishID = nil
        loadedRecipeDishID = nil
        recipeDraft = FoodStore.RecipeDraft()
    }

    /// Step 1's recipe choice goes into the draft once, on the way to Details.
    private func proceed() {
        draft.mealID = mealID
        draft.dishName = title.trimmedName
        draft.linkedDishID = linkedDishID ?? existingMatchedDish?.id
        draft.recipe = recipeDraft
        navigateToDetailsStep = true
    }

    private func syncMatchedDishRecipe() {
        guard let dish = existingMatchedDish else { return }
        guard dish.id != loadedRecipeDishID else { return }
        loadRecipe(from: dish)
    }

    private func loadRecipe(from dish: Dish) {
        loadedRecipeDishID = dish.id
        recipeDraft = FoodStore.RecipeDraft(
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

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        guard let meal else {
            if let initialDate { draft.eatenOn = initialDate }
            if let prefilledDishID, let dish = store.dish(prefilledDishID) {
                title = dish.name
                linkedDishID = dish.id
                loadRecipe(from: dish)
            }
            if let prefilledPartyID {
                draft.servedParties = [prefilledPartyID]
            } else if let lastParty = store.myParties.first {
                draft.servedParties = [lastParty.id]
            } else {
                draft.servedParties = []
            }
            return
        }

        let dish = store.dish(meal.dishID)
        title = dish?.name ?? ""
        linkedDishID = dish?.id
        draft.eatenOn = meal.eatenOn
        draft.notes = meal.notes
        draft.mealTitle = meal.title ?? ""
        draft.effort = meal.effort
        draft.repeatDesire = meal.repeatDesire
        draft.photos = FoodStore.PhotosDraft(existingPaths: meal.photoPaths)
        draft.servedParties = Set(store.parties(forMeal: meal.id).map(\.id))

        if let dish {
            loadRecipe(from: dish)
        }
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

