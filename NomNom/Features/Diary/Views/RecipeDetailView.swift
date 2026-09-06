import SwiftUI

/// Comprehensive detail view for a recipe:
/// - Harmonized centered arc hero presentation with photos, recipe title, and last cooked date
/// - Key-value details table (Created by, Cooking Time, Cuisine, Tags) matching MealDetailView
/// - Structured ingredients, instructions, and recipe page photos
/// - Cooked history list with auto-loading on scroll (when history exists)
/// - Top-right Edit button when owned by current user
struct RecipeDetailView: View {
    let recipeID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showMealEditor = false
    @State private var selectedMealForDetail: Meal?
    @State private var selectedPhotoIndex: Int?
    @State private var confirmDeleteRecipe = false

    init(recipeID: UUID, showCloseButton: Bool = false) {
        self.recipeID = recipeID
        self.showCloseButton = showCloseButton
    }

    init(recipe: Recipe, showCloseButton: Bool = false) {
        self.recipeID = recipe.id
        self.showCloseButton = showCloseButton
    }

    init(dishID: UUID, showCloseButton: Bool = false) {
        self.recipeID = dishID
        self.showCloseButton = showCloseButton
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
                    description: Text("It was deleted.")
                )
            }
        }
        .screenTitle(recipe?.name ?? "Recipe", displayMode: .inline)
        .toolbar {
            if showCloseButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Close")
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if let recipe {
                    Button {
                        Task { await store.toggleFavorite(recipe: recipe) }
                    } label: {
                        Image(systemName: store.isFavorite(recipe: recipe) ? "heart.fill" : "heart")
                            .foregroundStyle(store.isFavorite(recipe: recipe) ? DS.Color.accent : DS.Color.textSecondary)
                    }
                    .accessibilityLabel(store.isFavorite(recipe: recipe) ? "Remove from Favourites" : "Add to Favourites")
                }

                if let recipe, recipe.ownerID == store.userID {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            confirmDeleteRecipe = true
                        } label: {
                            Label("Delete recipe", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Recipe options")
                }
            }
        }
        .alert(
            "Delete this recipe?",
            isPresented: $confirmDeleteRecipe
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Recipe", role: .destructive) {
                if let recipe {
                    Task {
                        await store.delete(recipe: recipe)
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently remove this recipe.")
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
            VStack(spacing: DS.Spacing.section) {
                ArcHeroHeaderView(
                    photoPaths: allPhotos,
                    cuisine: recipe.cuisine,
                    title: recipe.name,
                    subtitle: recipeSubtitle(for: recipe),
                    alignment: .center,
                    onSelectPhoto: { index in
                        selectedPhotoIndex = index
                    }
                )
                .padding(.bottom, DS.Spacing.xs)

                // Centered "Use in Meal" action button above ingredients
                AppButton(
                    "Use in Meal",
                    variant: .primary,
                    style: .normal,
                    size: .md
                ) {
                    showMealEditor = true
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // 1. Ingredients
                if !recipe.ingredients.isEmpty {
                    RecipeIngredientsCard(ingredients: recipe.ingredients)
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                }

                // 2. Instructions
                if !recipe.instructions.isEmpty {
                    RecipeStepsCard(instructions: recipe.instructions)
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                }

                // 3. Recipe Page Photos (if any)
                if !recipe.recipePhotoPaths.isEmpty {
                    RecipePhotosCard(recipe: recipe)
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                }

                // 4. Details
                RecipeDetailInfoCard(recipe: recipe)
                    .padding(.horizontal, DS.Spacing.screenHorizontal)

                // 5. History
                if !history.isEmpty {
                    RecipeHistorySection(history: history) { meal in
                        selectedMealForDetail = meal
                    }
                    .padding(.horizontal, DS.Spacing.screenHorizontal)
                }
            }
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
    }

    private func recipeSubtitle(for recipe: Recipe) -> String {
        if let last = history.first?.eatenOn {
            return "Last cooked \(last.formatted(.dateTime.day().month(.abbreviated).year()))"
        } else {
            return "Never cooked"
        }
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
