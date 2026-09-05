import SwiftUI

/// A dedicated rating sheet for evaluating an eating experience:
/// - Personal Taste verdict (Loved, Ok, Not a fan)
/// - Household Rotation goal (One & Done, Sometimes, Staple)
/// - Household eaters ratings (if any)
/// - Eater reflections & comments
struct MealRatingSheet: View {
    let mealID: UUID
    var onDismiss: (() -> Void)? = nil

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var myReaction: Reaction?
    @State private var repeatDesire: RotationGoal?
    @State private var notes: String = ""
    @State private var eaterReactions: [UUID: Reaction] = [:]
    @State private var isSaving = false
    @State private var didLoad = false
    @State private var selectedPhotoIndex: Int?
    @State private var selectedRecipePhotoIndex: Int?

    private var meal: Meal? { store.meal(mealID) }
    private var mealTitle: String {
        guard let meal else { return "Meal" }
        return store.dishName(forMeal: meal)
    }

    private var mealRecipe: Recipe? {
        guard let meal else { return nil }
        return store.recipe(meal.dishID)
    }

    private var mealPhotos: [HeroPhotoItem] {
        guard let meal else { return [] }
        return meal.photoPaths.map { .remote(path: $0, bucket: SupabaseConfig.photoBucket) }
    }

    private var recipePhotos: [HeroPhotoItem] {
        guard let recipe = mealRecipe else { return [] }
        var items: [HeroPhotoItem] = []
        for p in recipe.recipePhotoPaths {
            if !items.contains(where: { $0.id == "\(SupabaseConfig.recipeBucket):\(p)" }) {
                items.append(.remote(path: p, bucket: SupabaseConfig.recipeBucket))
            }
        }
        for p in recipe.photoPaths {
            if !items.contains(where: { $0.id == "\(SupabaseConfig.photoBucket):\(p)" }) {
                items.append(.remote(path: p, bucket: SupabaseConfig.photoBucket))
            }
        }
        for p in store.photos(for: recipe) {
            if !items.contains(where: { $0.id == "\(SupabaseConfig.photoBucket):\(p)" }) {
                items.append(.remote(path: p, bucket: SupabaseConfig.photoBucket))
            }
        }
        if items.isEmpty {
            items.append(.fallback(cuisine: recipe.cuisine))
        }
        return items
    }

    var body: some View {
        NavigationStack {
            Group {
                if let meal {
                    ratingForm(for: meal)
                } else {
                    ContentUnavailableView(
                        "Meal Not Found",
                        systemImage: "questionmark.folder",
                        description: Text("This meal may have been removed.")
                    )
                }
            }
            .screenTitle("Rate Meal", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                onCancel: close,
                onSave: save
            )
            .onAppear(perform: loadData)
            .sheet(item: Binding(
                get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
                set: { selectedPhotoIndex = $0?.index }
            )) { wrapper in
                if let meal, wrapper.index < meal.photoPaths.count {
                    MealGalleryViewerSheet(paths: meal.photoPaths, initialIndex: wrapper.index)
                }
            }
            .sheet(item: Binding(
                get: { selectedRecipePhotoIndex.map { PhotoIndexWrapper(index: $0) } },
                set: { selectedRecipePhotoIndex = $0?.index }
            )) { wrapper in
                if let recipe = mealRecipe {
                    let paths = recipe.recipePhotoPaths.isEmpty ? recipe.photoPaths : recipe.recipePhotoPaths
                    let bucket = recipe.recipePhotoPaths.isEmpty ? SupabaseConfig.photoBucket : SupabaseConfig.recipeBucket
                    if !paths.isEmpty {
                        MealGalleryViewerSheet(paths: paths, initialIndex: min(wrapper.index, paths.count - 1), bucket: bucket, titlePrefix: "Recipe")
                    }
                }
            }
        }
    }

    // MARK: - Form Sections

    private func ratingForm(for meal: Meal) -> some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                // Top Hero Section: Harmonized Dual Arc Hero Header
                ArcHeroHeaderView(
                    items: mealPhotos,
                    recipeItems: recipePhotos,
                    cuisine: mealRecipe?.cuisine,
                    title: mealTitle,
                    date: meal.eatenOn,
                    alignment: .center,
                    onSelectMealPhoto: { index in
                        selectedPhotoIndex = index
                    },
                    onSelectRecipePhoto: { index in
                        selectedRecipePhotoIndex = index
                    }
                )

                // 1. Taste (Standalone)
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(
                        "How was it?",
                        trailingText: myReaction?.name,
                        trailingColor: myReaction?.text,
                        horizontalPadding: 4
                    )
                    TasteScoreSelector(selection: $myReaction)
                }

                // 2. Repeat Goal (Standalone)
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(
                        "How often to repeat",
                        trailingText: repeatDesire?.title,
                        trailingColor: DS.Color.accentText,
                        horizontalPadding: 4
                    )
                    RotationGoalSelector(selection: $repeatDesire)
                }

                // 3. Household Eaters (if present)
                if !store.myEaters.isEmpty {
                    MealRatingEatersCard(eaters: store.myEaters, reactions: $eaterReactions)
                }

                // 4. Notes & Review
                SectionCard(title: "Notes & Review") {
                    TextArea("Add your thoughts, flavor notes, or adjustments…", text: $notes, lineLimit: 3...6)
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
    }

    // MARK: - Actions

    private func loadData() {
        guard !didLoad, let meal else { return }
        didLoad = true
        myReaction = store.myRating(forMeal: meal.id)
        repeatDesire = meal.repeatDesire
        notes = meal.notes

        var loadedEaters: [UUID: Reaction] = [:]
        for eater in store.myEaters {
            if let r = store.rating(for: .eater(eater.id), on: meal.id) {
                loadedEaters[eater.id] = r.reaction
            }
        }
        eaterReactions = loadedEaters
    }

    private func save() {
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            var verdicts: [RaterRef: Reaction] = [:]
            if let myReaction {
                verdicts[.account(store.userID)] = myReaction
            }
            for (eaterID, reaction) in eaterReactions {
                verdicts[.eater(eaterID)] = reaction
            }

            let ok = await store.saveEaterRating(
                mealID: mealID,
                verdicts: verdicts,
                repeatDesire: repeatDesire,
                notes: notes.isEmpty ? nil : notes
            )
            isSaving = false
            if ok {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                close()
            }
        }
    }

    private func close() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

typealias MealEaterRatingSheet = MealRatingSheet

#Preview {
    NomNomPreview { store in
        if let meal = store.meals.first {
            MealRatingSheet(mealID: meal.id)
        }
    }
}
