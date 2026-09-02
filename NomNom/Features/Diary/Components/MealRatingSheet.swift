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

    private var meal: Meal? { store.meal(mealID) }

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
            .screenTitle("Rate Meal")
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
                if let meal, !meal.photoPaths.isEmpty {
                    MealGalleryViewerSheet(paths: meal.photoPaths, initialIndex: wrapper.index)
                }
            }
        }
    }

    // MARK: - Form Sections

    private func ratingForm(for meal: Meal) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Hero Section: Arced Photo Deck (if photos exist)
                if !meal.photoPaths.isEmpty {
                    RecipePhotoArcDeck(photoPaths: meal.photoPaths) { index in
                        selectedPhotoIndex = index
                    }
                }

                // Centered Dish Title & Date
                PageHeader(
                    title: store.dishName(forMeal: meal),
                    subtitle: meal.eatenOn.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
                )

                // 1. Taste
                SectionCard(title: "How was it?", caption: myReaction?.name) {
                    TactileOptionPicker(selection: $myReaction)
                }

                // 2. Repeat Goal
                SectionCard(title: "How often to repeat", caption: repeatDesire?.title) {
                    TactileOptionPicker(selection: $repeatDesire)
                }

                // 3. Household Eaters (if present)
                if !store.myEaters.isEmpty {
                    householdEatersCard
                }

                // 4. Notes & Review
                SectionCard(title: "Notes & Review") {
                    TextField("Add your thoughts, flavor notes, or adjustments…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(10)
                        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var householdEatersCard: some View {
        SectionCard(title: "Household Eaters", caption: "Family reactions") {
            VStack(spacing: 10) {
                ForEach(store.myEaters) { eater in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 26, height: 26)
                            Text(eater.name.prefix(1).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text(eater.name)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        TactileTasteSelector(selection: Binding(
                            get: { eaterReactions[eater.id] },
                            set: { eaterReactions[eater.id] = $0 }
                        ))
                    }
                    if eater.id != store.myEaters.last?.id {
                        Divider()
                    }
                }
            }
        }
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
