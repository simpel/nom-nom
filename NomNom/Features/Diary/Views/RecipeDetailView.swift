import SwiftUI

/// Comprehensive detail view for a recipe:
/// - Hero image arc deck displaying all photos associated with this recipe
/// - Header card with title, stats, duration, tags, and prominent "Cook this recipe" action button
/// - Horizontal scrollable line graph of general scores over time (filterable by dinner party)
/// - Cooked history list with auto-loading on scroll (filtered by selected dinner party)
/// - Top-right Edit mode toggle (reveals rename, merge, and housekeeping tools)
struct RecipeDetailView: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store

    @State private var showEditSheet = false
    @State private var selectedPartyID: UUID?
    @State private var showMealEditor = false
    @State private var selectedMealForDetail: Meal?
    @State private var selectedPhotoIndex: Int?

    init(recipeID: UUID) {
        self.recipeID = recipeID
    }

    init(dishID: UUID) {
        self.recipeID = dishID
    }

    private var recipe: Recipe? { store.recipe(recipeID) }
    private var history: [Meal] { store.servings(of: recipeID).sorted { $0.eatenOn > $1.eatenOn } }

    private var allPhotos: [String] {
        store.photos(for: recipeID)
    }

    var body: some View {
        Group {
            if let recipe {
                content(for: recipe)
            } else {
                ContentUnavailableView(
                    "Recipe is gone",
                    systemImage: "questionmark.folder",
                    description: Text("It was deleted or merged into another recipe.")
                )
            }
        }
        .screenTitle(recipe?.name ?? "Recipe")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            RecipeEditSheet(recipeID: recipeID)
        }
        .sheet(isPresented: $showMealEditor) {
            MealEditorView(mealID: nil, prefilledDishID: recipeID)
        }
        .sheet(item: $selectedMealForDetail) { meal in
            NavigationStack {
                MealDetailView(mealID: meal.id)
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedPhotoIndex != nil },
            set: { if !$0 { selectedPhotoIndex = nil } }
        )) {
            if !allPhotos.isEmpty {
                MealGalleryViewerSheet(
                    paths: allPhotos,
                    initialIndex: selectedPhotoIndex ?? 0
                )
            }
        }
    }

    @ViewBuilder
    private func content(for recipe: Recipe) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if !allPhotos.isEmpty {
                    RecipePhotoArcDeck(photoPaths: allPhotos) { index in
                        selectedPhotoIndex = index
                    }
                }

                RecipeHeaderCard(recipe: recipe, history: history) {
                    showMealEditor = true
                }

                if recipe.hasInstructions {
                    RecipeInstructionsCard(recipe: recipe)
                }

                RecipePartyHistorySection(recipeID: recipe.id)

                RecipeScoreHistorySection(
                    recipe: recipe,
                    history: history,
                    selectedPartyID: $selectedPartyID
                ) { meal in
                    selectedMealForDetail = meal
                }

                RecipeHistorySection(
                    history: history,
                    selectedPartyID: selectedPartyID
                ) { meal in
                    selectedMealForDetail = meal
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
