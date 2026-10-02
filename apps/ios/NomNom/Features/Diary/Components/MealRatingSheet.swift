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
    @State private var didAttemptFetch = false

    private var meal: Meal? { store.meal(mealID) }
    private var mealTitle: String {
        guard let meal else { return "Meal" }
        return store.dishName(forMeal: meal)
    }

    private var mealRecipe: Recipe? {
        guard let meal else { return nil }
        return store.recipe(meal.dishID)
    }

    private var mealPhotos: [PhotoCardSource] {
        guard let meal else { return [] }
        return meal.photoPaths.map { .remote(path: $0, cuisine: mealRecipe?.cuisine) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let meal {
                    ratingForm(for: meal)
                } else if !didAttemptFetch {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EmptyState("Meal is gone", message: "It looks like this meal was deleted.", layout: .screen)
                        .padding(.horizontal, DS.Spacing.gutter)
                }
            }
            .screenTitle("Rate Meal", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                onCancel: close,
                onSave: save
            )
            .onAppear(perform: loadData)
            .task {
                guard meal == nil else { return }
                await store.fetchMealIfMissing(mealID)
                didAttemptFetch = true
                loadData()
            }
            .sheet(item: Binding(
                get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
                set: { selectedPhotoIndex = $0?.index }
            )) { wrapper in
                if let meal, wrapper.index < meal.photoPaths.count {
                    MediaViewerSheet(.paths(meal.photoPaths), startIndex: wrapper.index)
                }
            }
            .sheet(item: Binding(
                get: { selectedRecipePhotoIndex.map { PhotoIndexWrapper(index: $0) } },
                set: { selectedRecipePhotoIndex = $0?.index }
            )) { wrapper in
                if let paths = mealRecipe?.ratingHeaderPhotoPaths, !paths.isEmpty {
                    MediaViewerSheet(.paths(paths, bucket: SupabaseConfig.recipeBucket), startIndex: wrapper.index, title: "Recipe")
                }
            }
        }
    }

    // MARK: - Form Sections

    private func ratingForm(for meal: Meal) -> some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                MealRatingPhotoHeader(
                    mealPhotos: mealPhotos,
                    recipePhotos: mealRecipe?.ratingHeaderPhotos ?? [],
                    cuisine: mealRecipe?.cuisine,
                    title: mealTitle,
                    date: meal.eatenOn,
                    onSelectMealPhoto: { index in
                        selectedPhotoIndex = index
                    },
                    onSelectRecipePhoto: { index in
                        selectedRecipePhotoIndex = index
                    }
                )

                // 1–2. Taste and repeat goal
                RatingBlocks(reaction: $myReaction, repeatDesire: $repeatDesire)

                // 3. Household Eaters (if present)
                if !store.myEaters.isEmpty {
                    MealRatingEatersCard(eaters: store.myEaters, reactions: $eaterReactions)
                }

                // 4. Notes & Review
                SectionCard("Notes & Review") {
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
