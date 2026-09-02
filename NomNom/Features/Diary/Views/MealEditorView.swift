import SwiftUI
import PhotosUI

/// Add or edit one meal: multiple photos, title (with existing dish matching), date, dinner party serving, notes.
struct MealEditorView: View {
    var mealID: UUID?
    var initialDate: Date?
    var prefilledDishID: UUID?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var linkedDishID: UUID?
    @State private var date = Date.now
    @State private var notes = ""
    @State private var effort: EffortLevel?
    @State private var repeatDesire: RotationGoal?
    @State private var verdicts: [RaterRef: Reaction] = [:]
    @State private var tagsText = ""
    @State private var selectedParties: Set<UUID> = []

    @State private var photosDraft = FoodStore.PhotosDraft()
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var loadedRecipeDishID: UUID?

    @State private var isSaving = false
    @State private var didLoad = false

    @State private var showingCreateParty = false
    @State private var newPartyName = ""
    @State private var showDishPickerSheet = false
    @State private var showRecipeEditorSheet = false
    @State private var navigateToRecipeStep = false
    @State private var navigateToVerdict = false

    private var meal: Meal? { mealID.flatMap { store.meal($0) } }
    private var isEditing: Bool { mealID != nil }
    private var canProceed: Bool { !title.trimmedName.isEmpty && !isSaving }

    private var existingMatchedDish: Dish? {
        if let linkedDishID, let dish = store.dish(linkedDishID) { return dish }
        let normalized = title.trimmedName.normalizedForMatching
        guard !normalized.isEmpty else { return nil }
        return store.myDishes.first { $0.normalizedName == normalized }
    }

    private var isExistingDish: Bool { existingMatchedDish != nil }

    private var currentDraft: FoodStore.MealDraft {
        let name = title.trimmedName
        let tags = TagsParser.parse(tagsText)

        return FoodStore.MealDraft(mealID: mealID,
                                   dishName: name,
                                   linkedDishID: linkedDishID ?? existingMatchedDish?.id,
                                   eatenOn: date,
                                   notes: notes,
                                   tags: tags,
                                   photos: photosDraft,
                                   effort: effort,
                                   repeatDesire: repeatDesire,
                                   verdicts: verdicts,
                                   servedParties: selectedParties,
                                   recipe: recipeDraft)
    }

    private var currentDraftBinding: Binding<FoodStore.MealDraft> {
        Binding(
            get: { currentDraft },
            set: { updated in
                recipeDraft = updated.recipe ?? recipeDraft
                tagsText = updated.tags.joined(separator: ", ")
                notes = updated.notes
                effort = updated.effort
                repeatDesire = updated.repeatDesire
                verdicts = updated.verdicts
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PageHeader(title: isEditing ? "Edit meal" : "New meal")

                    MealPhotosPickerSection(draft: $photosDraft)

                    MealEditorRecipeSection(
                        title: $title,
                        existingMatchedRecipe: existingMatchedDish,
                        isExistingRecipe: isExistingDish,
                        onPickRecipe: { showDishPickerSheet = true },
                        onEditRecipe: { showRecipeEditorSheet = true },
                        onRemoveRecipe: removeSelectedDish
                    )

                    MealEditorCookingTimeSection(effort: $effort)

                    MealEditorPartiesSection(
                        selectedParties: $selectedParties,
                        onCreateParty: { showingCreateParty = true }
                    )

                    MealEditorDetailsSection(
                        date: $date,
                        notes: $notes,
                        meal: meal,
                        isSaving: isSaving,
                        onDelete: deleteMeal
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(DS.Color.bg)
            .screenTitle(isEditing ? "Edit meal" : "New meal", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else if isEditing {
                        Button {
                            save()
                        } label: {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                        .disabled(!canProceed)
                    } else {
                        Button("Next") {
                            proceed()
                        }
                        .disabled(!canProceed)
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToRecipeStep) {
                MealRecipeStepView(draft: currentDraftBinding, onDismiss: { dismiss() })
            }
            .navigationDestination(isPresented: $navigateToVerdict) {
                MealVerdictStepView(draft: currentDraft, onDismiss: { dismiss() })
            }
            .sheet(isPresented: $showRecipeEditorSheet) {
                DishRecipeEditSheet(dishName: $title,
                                    recipeDraft: $recipeDraft,
                                    tagsText: $tagsText)
            }
            .sheet(isPresented: $showDishPickerSheet) {
                RecipePickerSheet(
                    onSelectExistingRecipe: { recipe in
                        title = recipe.name
                        linkedDishID = recipe.id
                        tagsText = recipe.tags.joined(separator: ", ")
                        loadRecipe(from: recipe)
                    },
                    onSelectNewRecipe: { name in
                        title = name
                        linkedDishID = nil
                        loadedRecipeDishID = nil
                        recipeDraft = FoodStore.RecipeDraft()
                        tagsText = ""
                    }
                )
            }
            .alert("New Dinner Party", isPresented: $showingCreateParty) {
                TextField("Party name", text: $newPartyName)
                Button("Create") {
                    let name = newPartyName.trimmedName
                    guard !name.isEmpty else { return }
                    Task {
                        if let created = await store.createParty(name: name) {
                            selectedParties.insert(created.id)
                            newPartyName = ""
                        }
                    }
                }
                Button("Cancel", role: .cancel) { newPartyName = "" }
            }
            .onAppear(perform: loadIfNeeded)
            .onChange(of: linkedDishID) { _, _ in syncMatchedDishRecipe() }
            .onChange(of: title) { _, _ in syncMatchedDishRecipe() }
            .interactiveDismissDisabled(isSaving)
            .alert("Couldn't save meal",
                   isPresented: Binding(get: { store.errorMessage != nil },
                                        set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private func removeSelectedDish() {
        title = ""
        linkedDishID = nil
        loadedRecipeDishID = nil
        recipeDraft = FoodStore.RecipeDraft()
        tagsText = ""
    }

    private func deleteMeal() {
        guard let meal else { return }
        Task {
            await store.delete(meal: meal)
            dismiss()
        }
    }

    private func proceed() {
        if isExistingDish {
            navigateToVerdict = true
        } else {
            navigateToRecipeStep = true
        }
    }

    private func syncMatchedDishRecipe() {
        guard let dish = existingMatchedDish else { return }
        guard dish.id != loadedRecipeDishID else { return }
        loadRecipe(from: dish)
    }

    private func loadRecipe(from dish: Dish) {
        loadedRecipeDishID = dish.id
        tagsText = dish.tags.joined(separator: ", ")
        recipeDraft = FoodStore.RecipeDraft(
            text: dish.recipeText,
            existingPhotoPaths: dish.recipePhotoPaths,
            addedPhotoData: [],
            removedPhotoPaths: [],
            effort: dish.effort
        )
        if effort == nil, let dishEffort = dish.effort {
            effort = dishEffort
        }
        if photosDraft.isEmpty {
            let firstPhoto = store.servings(of: dish.id)
                .sorted(by: { $0.eatenOn > $1.eatenOn })
                .first(where: { !$0.photoPaths.isEmpty })?
                .photoPaths.first
            if let firstPhoto {
                photosDraft = FoodStore.PhotosDraft(existingPaths: [firstPhoto])
            }
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        guard let meal else {
            if let initialDate { date = initialDate }
            if let prefilledDishID, let dish = store.dish(prefilledDishID) {
                title = dish.name
                linkedDishID = dish.id
                tagsText = dish.tags.joined(separator: ", ")
                loadRecipe(from: dish)
            }
            if let party = store.currentParty {
                selectedParties.insert(party.id)
            }
            return
        }

        let dish = store.dish(meal.dishID)
        title = dish?.name ?? ""
        linkedDishID = dish?.id
        date = meal.eatenOn
        notes = meal.notes
        effort = meal.effort
        repeatDesire = meal.repeatDesire
        photosDraft = FoodStore.PhotosDraft(existingPaths: meal.photoPaths)
        tagsText = (dish?.tags ?? []).joined(separator: ", ")
        selectedParties = Set(store.parties(forMeal: meal.id).map(\.id))

        if let dish {
            loadRecipe(from: dish)
        }

        let mine = Set(store.myEaters.map(\.id))
        var loaded: [RaterRef: Reaction] = [:]
        for rating in store.ratings(forMeal: meal.id) {
            switch rating.source {
            case .eater(let id) where mine.contains(id):
                loaded[.eater(id)] = rating.reaction
            case .account(let id) where id == store.userID:
                loaded[.account(id)] = rating.reaction
            default:
                continue
            }
        }
        verdicts = loaded
    }

    private func save() {
        let name = title.trimmedName
        guard !name.isEmpty else { return }

        let draft = currentDraft
        isSaving = true
        Task {
            let ok = await store.save(draft)
            isSaving = false
            if ok { dismiss() }
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

