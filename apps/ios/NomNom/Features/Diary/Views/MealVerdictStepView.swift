import SwiftUI

/// Step 2 of logging a meal: A rich hero moment to evaluate your personal Taste verdict and Rotation goal.
struct MealVerdictStepView: View {
    let draft: FoodStore.MealDraft
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var myReaction: Reaction?
    @State private var repeatDesire: RotationGoal?
    @State private var isSaving = false
    @State private var selectedPhotoIndex: Int?
    @State private var selectedRecipePhotoIndex: Int?
    @State private var hasInitialized = false

    private var matchedRecipe: Recipe? {
        if let id = draft.linkedDishID {
            return store.recipe(id)
        }
        return store.recipes.first { $0.normalizedName == draft.dishName.normalizedForMatching }
    }

    private var resolvedCuisine: String? {
        draft.recipe?.cuisine ?? matchedRecipe?.cuisine
    }

    private var mealPhotos: [PhotoCardSource] {
        draft.photos.items.map { item in
            switch item {
            case .existing(let path):
                return .remote(path: path, cuisine: resolvedCuisine)
            case .added(_, let data):
                return .data(data, cuisine: resolvedCuisine)
            }
        }
    }

    /// The matched recipe's photos (these open in the viewer). Without a matched recipe,
    /// a new recipe draft's photos show read-only.
    private var recipePhotos: [PhotoCardSource] {
        if let matchedRecipe { return matchedRecipe.ratingHeaderPhotos }
        guard let recipeDraft = draft.recipe else { return [] }
        let stored: [PhotoCardSource] = recipeDraft.existingPhotoPaths.map {
            .remote(path: $0, bucket: SupabaseConfig.recipeBucket, cuisine: resolvedCuisine)
        }
        return stored + recipeDraft.addedPhotoData.map { .data($0, cuisine: resolvedCuisine) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                MealRatingPhotoHeader(
                    mealPhotos: mealPhotos,
                    recipePhotos: recipePhotos,
                    cuisine: resolvedCuisine,
                    title: draft.dishName.isEmpty ? "Rate Meal" : draft.dishName,
                    date: draft.eatenOn,
                    onSelectMealPhoto: { index in
                        selectedPhotoIndex = index
                    },
                    onSelectRecipePhoto: { index in
                        selectedRecipePhotoIndex = index
                    }
                )

                RatingBlocks(reaction: $myReaction, repeatDesire: $repeatDesire)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.sheet)
        .screenTitle("Rate Meal", displayMode: .inline)
        .stepCommitToolbar(isSaving: isSaving, onSave: save)
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { wrapper in
            if wrapper.index < draft.photos.count {
                MediaViewerSheet(.photosDraft(draft.photos), startIndex: wrapper.index)
            }
        }
        .sheet(item: Binding(
            get: { selectedRecipePhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedRecipePhotoIndex = $0?.index }
        )) { wrapper in
            if let paths = matchedRecipe?.ratingHeaderPhotoPaths, !paths.isEmpty {
                MediaViewerSheet(.paths(paths, bucket: SupabaseConfig.recipeBucket), startIndex: wrapper.index, title: "Recipe")
            }
        }
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                myReaction = draft.verdicts[.account(store.userID)]
                repeatDesire = draft.repeatDesire
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.height > 90 && abs(value.translation.width) < 60 {
                        onDismiss()
                    }
                }
        )
        .alert("Couldn't save meal",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func save() {
        var finalDraft = draft
        var updatedVerdicts = draft.verdicts
        let myRef: RaterRef = .account(store.userID)
        if let reaction = myReaction {
            updatedVerdicts[myRef] = reaction
        } else {
            updatedVerdicts.removeValue(forKey: myRef)
        }
        finalDraft.verdicts = updatedVerdicts
        finalDraft.repeatDesire = repeatDesire

        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let ok = await store.save(finalDraft)
            isSaving = false
            if ok {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss()
            }
        }
    }
}
