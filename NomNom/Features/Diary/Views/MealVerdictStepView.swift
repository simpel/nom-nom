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

    private var mealPhotos: [HeroPhotoItem] {
        draft.photos.items.map { item in
            switch item {
            case .existing(let path):
                return .remote(path: path, bucket: SupabaseConfig.photoBucket)
            case .added(let id, let data):
                return .local(id: id.uuidString, data: data)
            }
        }
    }

    private var recipePhotos: [HeroPhotoItem] {
        var items: [HeroPhotoItem] = []
        if let matchedRecipe {
            for p in matchedRecipe.recipePhotoPaths {
                if !items.contains(where: { $0.id == "\(SupabaseConfig.recipeBucket):\(p)" }) {
                    items.append(.remote(path: p, bucket: SupabaseConfig.recipeBucket))
                }
            }
            for p in matchedRecipe.photoPaths {
                if !items.contains(where: { $0.id == "\(SupabaseConfig.recipeBucket):\(p)" }) {
                    items.append(.remote(path: p, bucket: SupabaseConfig.recipeBucket))
                }
            }
        }
        if let recipeDraft = draft.recipe {
            for p in recipeDraft.existingPhotoPaths {
                if !items.contains(where: { $0.id == "\(SupabaseConfig.recipeBucket):\(p)" }) {
                    items.append(.remote(path: p, bucket: SupabaseConfig.recipeBucket))
                }
            }
            for (idx, data) in recipeDraft.addedPhotoData.enumerated() {
                let alreadyInItems = items.contains { item in
                    if case .local(_, let existingData) = item {
                        return existingData == data
                    }
                    return false
                }
                if !alreadyInItems {
                    items.append(.local(id: "recipe-added-\(idx)", data: data))
                }
            }
        }
        if items.isEmpty, (matchedRecipe != nil || draft.recipe != nil || resolvedCuisine != nil) {
            items.append(.fallback(cuisine: resolvedCuisine))
        }
        return items
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                // Top Hero Section: Harmonized Dual Arc Hero Header
                ArcHeroHeaderView(
                    items: mealPhotos,
                    recipeItems: recipePhotos,
                    cuisine: resolvedCuisine,
                    title: draft.dishName.isEmpty ? "Rate Meal" : draft.dishName,
                    date: draft.eatenOn,
                    alignment: .center,
                    onSelectMealPhoto: { index in
                        selectedPhotoIndex = index
                    },
                    onSelectRecipePhoto: { index in
                        selectedRecipePhotoIndex = index
                    }
                )

                // Axis 1: Taste Verdict (Standalone 6-tile selector)
                tasteSection

                // Axis 2: Rotation Goal (Standalone 3-card selector)
                rotationSection
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .screenTitle("Rate Meal", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { wrapper in
            if wrapper.index < draft.photos.count {
                MealPhotoViewerSheet(draft: draft.photos, initialIndex: wrapper.index)
            }
        }
        .sheet(item: Binding(
            get: { selectedRecipePhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedRecipePhotoIndex = $0?.index }
        )) { wrapper in
            if let matchedRecipe {
                let paths = matchedRecipe.recipePhotoPaths.isEmpty ? matchedRecipe.photoPaths : matchedRecipe.recipePhotoPaths
                let bucket = SupabaseConfig.recipeBucket
                if !paths.isEmpty {
                    MealGalleryViewerSheet(paths: paths, initialIndex: min(wrapper.index, paths.count - 1), bucket: bucket, titlePrefix: "Recipe")
                }
            }
        }
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                myReaction = draft.verdicts[.account(store.userID)]
                repeatDesire = draft.repeatDesire
            }
        }
        .interactiveDismissDisabled(isSaving)
        .presentationDragIndicator(.visible)
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

    // MARK: - Taste Section

    private var tasteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "How was it?",
                trailingText: myReaction?.name,
                trailingColor: myReaction?.text,
                horizontalPadding: 4
            )
            TasteScoreSelector(selection: $myReaction)
        }
    }

    // MARK: - Rotation Section

    private var rotationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "How often to repeat",
                trailingText: repeatDesire?.title,
                trailingColor: DS.Color.accentText,
                horizontalPadding: 4
            )
            RotationGoalSelector(selection: $repeatDesire)
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
