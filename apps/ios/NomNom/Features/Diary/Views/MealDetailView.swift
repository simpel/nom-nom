import SwiftUI

/// One meal on the design system's detail layout (see MealDetailContent): photos,
/// the table's verdict, the score vs last time, the recipe, who rated, the cook's
/// note and every time this group had the dish.
///
/// Pushed, the navigation bar is hidden and an elevated back button (plus the cook's
/// options menu) floats over the content; presented modally (`showCloseButton`) it
/// keeps the sheet close toolbar.
struct MealDetailView: View {
    let mealID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var showRecipeSheet = false
    @State private var showRatingSheet = false
    @State private var showScoreSheet = false
    @State private var selectedPartyForSheet: Party?
    @State private var selectedPhotoIndex: Int?
    @State private var selectedRecipePhotoIndex: Int?
    @State private var pushedMealID: UUID?
    @State private var confirmDeleteMeal = false
    @State private var didAttemptFetch = false
    @State private var deleteError: String?

    private var meal: Meal? { store.meal(mealID) }
    private var canEdit: Bool { meal?.createdBy == store.userID }

    var body: some View {
        chrome {
            Group {
                if let meal {
                    MealDetailContent(meal: meal, topInset: topInset, actions: actions(for: meal))
                } else if !didAttemptFetch {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EmptyState("Meal is gone", message: "It looks like this meal was deleted.", layout: .screen)
                        .padding(.horizontal, DS.Spacing.gutter)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(DS.Color.bg)
        }
        .task {
            guard meal == nil else { return }
            await store.fetchMealIfMissing(mealID)
            didAttemptFetch = true
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
        .sheet(isPresented: $showRatingSheet) { MealRatingSheet(mealID: mealID) }
        .sheet(isPresented: $showScoreSheet) {
            if let meal { MealScoreBreakdownSheet(meal: meal) }
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
    }

    /// Room for the floating top bar when pushed; a small inset under the sheet toolbar.
    private var topInset: CGFloat {
        showCloseButton ? DS.Spacing.s2 : AppButtonSize.md.height + DS.Spacing.s2 + DS.Spacing.s3
    }

    @ViewBuilder
    private func chrome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if showCloseButton {
            content()
                .screenTitle(meal.map { store.dishName(forMeal: $0) } ?? "Meal", displayMode: .inline)
                .sheetCloseToolbar()
                .toolbar {
                    if canEdit {
                        ToolbarItem(placement: .topBarTrailing) {
                            MealDetailOptionsMenu(onEdit: { showEditor = true }, onDelete: { confirmDeleteMeal = true }) {
                                Image(systemName: "ellipsis").fontWeight(.semibold)
                            }
                        }
                    }
                }
        } else {
            content()
                .toolbar(.hidden, for: .navigationBar)
                .overlay(alignment: .top) {
                    MealDetailTopBar(
                        canEdit: canEdit,
                        onBack: { dismiss() },
                        onEdit: { showEditor = true },
                        onDelete: { confirmDeleteMeal = true }
                    )
                }
        }
    }

    private func actions(for meal: Meal) -> MealDetailActions {
        let mealPhotoCount = meal.photoPaths.count
        return MealDetailActions(
            onAddPhoto: canEdit ? { showEditor = true } : nil,
            onSelectPhoto: { index in
                if index < mealPhotoCount {
                    selectedPhotoIndex = index
                } else {
                    selectedRecipePhotoIndex = index - mealPhotoCount
                }
            },
            onRate: { showRatingSheet = true },
            onOpenScore: { showScoreSheet = true },
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
