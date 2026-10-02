import SwiftUI

/// A recipe's detail screen, composed top to bottom on `bg`: PhotoStrip, DetailHeader
/// (cuisine, name, last cooked, facts, "Use in a meal"), the household and health
/// ScoreCards, ingredients, steps, recipe pages, cooking history and details.
/// The owner gets Edit / Delete / Generate photo in the toolbar menu.
struct RecipeDetailView: View {
    let recipeID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State var fallbackRecipe: Recipe?
    @State var isLoadingRemote = false
    @State var showEditSheet = false
    @State var showMealEditor = false
    @State var selectedMealForDetail: Meal?
    @State var selectedPhotoIndex: Int?
    @State var confirmDeleteRecipe = false
    @State var deleteError: String?
    @State var isAnalyzingHealth = false
    @State var healthAnalysisFailed = false
    @State var showHealthRationale = false
    @State var showGlobalLeaderboard = false
    @State var isGeneratingPhoto = false

    init(recipeID: UUID, showCloseButton: Bool = false) {
        self.recipeID = recipeID
        self.showCloseButton = showCloseButton
        self._fallbackRecipe = State(initialValue: nil)
    }

    init(recipe: Recipe, showCloseButton: Bool = false) {
        self.recipeID = recipe.id
        self.showCloseButton = showCloseButton
        self._fallbackRecipe = State(initialValue: recipe)
    }

    init(dishID: UUID, showCloseButton: Bool = false) {
        self.init(recipeID: dishID, showCloseButton: showCloseButton)
    }

    var recipe: Recipe? { store.recipe(recipeID) ?? fallbackRecipe }
    var history: [Meal] { store.servings(of: recipeID).sorted { $0.eatenOn > $1.eatenOn } }

    /// Dish photos, then recipe pages, without duplicates (all in the recipe bucket).
    var allPhotos: [String] {
        guard let recipe else { return store.photos(for: recipeID) }
        var paths: [String] = []
        for path in recipe.photoPaths + recipe.recipePhotoPaths where !paths.contains(path) {
            paths.append(path)
        }
        return paths
    }

    var body: some View {
        Group {
            if let recipe {
                content(for: recipe)
            } else if store.isLoading || isLoadingRemote {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyState("Recipe is gone", message: "It was deleted.")
                    .padding(.horizontal, DS.Spacing.gutter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DS.Color.bg)
            }
        }
        .screenTitle(recipe?.name ?? "Recipe", displayMode: .inline)
        .task { await loadRecipeAndHealth() }
        .toolbar { toolbarContent }
        .alert("Delete this recipe?", isPresented: $confirmDeleteRecipe) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Recipe", role: .destructive) { deleteRecipe() }
        } message: {
            Text("This will permanently remove this recipe.")
        }
        .alert("Couldn't Delete Recipe", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
        .sheet(isPresented: $showEditSheet) {
            RecipeEditSheet(recipeID: recipeID)
        }
        .sheet(isPresented: $showMealEditor) {
            MealEditorView(mealID: nil, prefilledDishID: recipeID)
        }
        .sheet(item: $selectedMealForDetail) { meal in
            NavigationStack {
                MealDetailView(mealID: meal.id, showCloseButton: true)
            }
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { wrapper in
            if !allPhotos.isEmpty {
                MediaViewerSheet(.paths(allPhotos, bucket: SupabaseConfig.recipeBucket), startIndex: wrapper.index)
            }
        }
        .sheet(isPresented: $showHealthRationale) {
            if let recipe, let healthIndex = recipe.healthIndex {
                RecipeHealthRationaleSheet(recipe: recipe, healthIndex: healthIndex)
            }
        }
        .sheet(isPresented: $showGlobalLeaderboard) {
            RecipeLeaderboardSheet(highlightedRecipeID: recipe?.id)
        }
    }

    private func content(for recipe: Recipe) -> some View {
        let isOwner = recipe.ownerID == store.userID
        return ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                PhotoStrip(
                    photos: allPhotos.map { .remote(path: $0, bucket: SupabaseConfig.recipeBucket, cuisine: recipe.cuisine) },
                    onAddPhoto: isOwner ? { showEditSheet = true } : nil,
                    onSelect: { selectedPhotoIndex = $0 }
                )

                RecipeDetailHeader(recipe: recipe, history: history) {
                    showMealEditor = true
                }

                RecipeScoreCards(
                    recipe: recipe,
                    isAnalyzingHealth: isAnalyzingHealth,
                    healthAnalysisFailed: healthAnalysisFailed,
                    onOpenHealth: { showHealthRationale = true },
                    onOpenLeaderboard: { showGlobalLeaderboard = true }
                )

                if !recipe.ingredients.isEmpty {
                    RecipeIngredientsCard(ingredients: recipe.ingredients)
                }

                if !recipe.instructions.isEmpty {
                    RecipeStepsCard(instructions: recipe.instructions)
                }

                if !recipe.recipePhotoPaths.isEmpty {
                    RecipePhotosCard(recipe: recipe)
                }

                if !history.isEmpty {
                    RecipeHistorySection(history: history) { meal in
                        selectedMealForDetail = meal
                    }
                }

                RecipeDetailInfoCard(recipe: recipe)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s12)
        }
        .background(DS.Color.bg)
    }
}

typealias DishDetailView = RecipeDetailView

#Preview {
    NomNomPreview { store in
        if let firstRecipe = store.dishes.first {
            RecipeDetailView(recipeID: firstRecipe.id)
        }
    }
}
