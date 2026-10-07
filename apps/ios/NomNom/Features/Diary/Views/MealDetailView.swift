import SwiftUI

/// One meal on the design system's detail layout (see MealDetailContent): the dish
/// and the table's verdict, photos, the score vs last time, the recipe, who rated, the
/// cook's note and every time this group had the dish.
///
/// The native navigation bar carries the back button (or, presented modally with
/// `showCloseButton`, the sheet close button) and the PageMenu with this meal's
/// Edit / Share / Delete group.
struct MealDetailView: View {
    let mealID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var showRecipeSheet = false
    @State private var showRatingSheet = false
    @State private var showScoreSheet = false
    @State private var showRemindSheet = false
    @State private var selectedPartyForSheet: Party?
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoIndex: Int?
    @State private var selectedRecipePhotoIndex: Int?
    @State private var pushedMealID: UUID?
    @State private var confirmDeleteMeal = false
    @State private var didAttemptFetch = false
    @State private var deleteError: String?
    @State private var shareImage: Image?

    private var meal: Meal? { store.meal(mealID) }
    private var canEdit: Bool { meal?.createdBy == store.userID }

    var body: some View {
        chrome {
            Group {
                if let meal {
                    MealDetailContent(meal: meal, topInset: topInset, actions: actions(for: meal))
                } else if !didAttemptFetch {
                    ScreenSkeleton(label: "Loading meal")
                } else {
                    EmptyState("Meal is gone", message: "It looks like this meal was deleted.", layout: .screen)
                        .padding(.horizontal, DS.Spacing.gutter)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(DS.Color.bg)
        }
        .task {
            if meal == nil {
                await store.fetchMealIfMissing(mealID)
                didAttemptFetch = true
            }
            if let photoPath = meal?.photoPaths.first ?? store.recipe(meal?.recipeID ?? UUID())?.photoPaths.first {
                if let data = await PhotoCache.shared.data(for: photoPath, bucket: SupabaseConfig.photoBucket),
                   let uiImage = UIImage(data: data) {
                    shareImage = Image(uiImage: uiImage)
                }
            }
        }
        .alert("Delete this meal?", isPresented: $confirmDeleteMeal) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Meal", role: .destructive) { deleteMeal() }
        } message: {
            Text("This will permanently remove this meal log.")
        }
        .alert("Couldn't Delete Meal", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
        .sheet(isPresented: $showEditor) { MealEditorView(mealID: mealID) }
        .sheet(isPresented: $showRatingSheet) { RateMealSheet(mealID: mealID) }
        .sheet(isPresented: $showScoreSheet) {
            if let meal { MealScoreBreakdownSheet(meal: meal) }
        }
        .sheet(isPresented: $showRemindSheet) {
            if let meal { RemindRatersSheet(meal: meal) }
        }
        .sheet(isPresented: $showRecipeSheet) {
            if let meal {
                NavigationStack {
                    RecipeDetailView(recipeID: meal.recipeID, showCloseButton: true)
                }
            }
        }
        .sheet(item: $selectedPartyForSheet) { party in
            NavigationStack {
                PartyDetailView(partyID: party.id, showCloseButton: true)
            }
        }
        .sheet(item: photoBinding($selectedPhotoIndex)) { wrapper in
            if let meal {
                MediaViewerSheet(.paths(meal.photoPaths), startIndex: wrapper.index)
            }
        }
        .sheet(item: photoBinding($selectedRecipePhotoIndex)) { wrapper in
            let paths = MealDetailContent.recipePhotoPaths(meal.flatMap { store.recipe($0.recipeID) })
            if !paths.isEmpty {
                MediaViewerSheet(.paths(paths, bucket: SupabaseConfig.recipeBucket), startIndex: wrapper.index, title: "Recipe")
            }
        }
        .navigationDestination(item: $pushedMealID) { id in
            MealDetailView(mealID: id)
        }
        .avatarPhotoPicker(isPresented: $showingPhotoPicker) { data in
            if let meal { addPhotoData(data, to: meal, prepend: false) }
        }
    }

    /// A small inset under the navigation bar.
    private var topInset: CGFloat { DS.Spacing.s2 }

    @ViewBuilder
    private func chrome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let page = content()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let meal {
                        if let shareImage {
                            ShareLink(item: meal.shareURL, subject: Text(store.dishName(forMeal: meal)), preview: SharePreview(store.dishName(forMeal: meal), image: shareImage)) {
                                Image(systemName: "square.and.arrow.up").fontWeight(.semibold)
                            }
                            .accessibilityLabel("Share meal")
                            .barItemStyle()
                        } else {
                            ShareLink(item: meal.shareURL, subject: Text(store.dishName(forMeal: meal)), preview: SharePreview(store.dishName(forMeal: meal))) {
                                Image(systemName: "square.and.arrow.up").fontWeight(.semibold)
                            }
                            .accessibilityLabel("Share meal")
                            .barItemStyle()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PageMenu { mealMenu }
                }
            }
        if showCloseButton {
            page
                .screenTitle(meal.map { store.dishName(forMeal: $0) } ?? "Meal", displayMode: .inline)
                .sheetCloseToolbar()
        } else {
            page.screenTitle("", displayMode: .inline)
        }
    }

    /// The page menu's "This meal" group: Edit and Delete for the cook.
    @ViewBuilder
    private var mealMenu: some View {
        if let meal {
            Section {
                if canEdit {
                    Button("Edit meal", systemImage: "pencil") { showEditor = true }
                    Button("Delete meal", systemImage: "trash", role: .destructive) { confirmDeleteMeal = true }
                }
            }
        }
    }

    private func addPhotoData(_ data: Data, to meal: Meal, prepend: Bool) {
        let existing = meal.photoPaths.map { FoodStore.PhotosDraft.Item.existing(path: $0) }
        let newItem = FoodStore.PhotosDraft.Item.added(id: UUID(), data: data)
        let items = prepend ? [newItem] + existing : existing + [newItem]
        let draft = FoodStore.PhotosDraft(items: items)
        Task {
            do {
                try await store.applyPhotos(draft, to: meal)
            } catch {
                // Ignore for now or handle via store.errorMessage
            }
        }
    }

    private func actions(for meal: Meal) -> MealDetailActions {
        let mealPhotoCount = meal.photoPaths.count
        return MealDetailActions(
            onAddPhoto: canEdit ? { showingPhotoPicker = true } : nil,
            onAddPhotoData: canEdit ? { data in addPhotoData(data, to: meal, prepend: true) } : nil,
            onSelectPhoto: { index in
                if index < mealPhotoCount {
                    selectedPhotoIndex = index
                } else {
                    selectedRecipePhotoIndex = index - mealPhotoCount
                }
            },
            onRate: store.canRate(meal: meal) ? { showRatingSheet = true } : nil,
            onOpenScore: { showScoreSheet = true },
            onRemind: { showRemindSheet = true },
            onOpenRecipe: { showRecipeSheet = true },
            onOpenParty: { selectedPartyForSheet = $0 },
            onOpenMeal: { pushedMealID = $0 }
        )
    }

    private func photoBinding(_ index: Binding<Int?>) -> Binding<PhotoIndexWrapper?> {
        Binding(
            get: { index.wrappedValue.map { PhotoIndexWrapper(index: $0) } },
            set: { index.wrappedValue = $0?.index }
        )
    }

    private func deleteMeal() {
        guard let meal else { return }
        Task {
            await store.delete(meal: meal)
            if store.errorMessage == nil {
                dismiss()
            } else {
                deleteError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}

#Preview("Light") {
    NomNomPreview { store in
        if let firstMeal = store.meals.first {
            MealDetailView(mealID: firstMeal.id)
        }
    }
}

#Preview("Dark") {
    NomNomPreview { store in
        if let firstMeal = store.meals.first {
            MealDetailView(mealID: firstMeal.id)
        }
    }
    .preferredColorScheme(.dark)
}
