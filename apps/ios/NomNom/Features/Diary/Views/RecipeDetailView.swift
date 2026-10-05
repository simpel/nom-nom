import SwiftUI

/// A recipe's detail screen ("Nom Nom iOS" canvas), top to bottom on `bg`: ScreenHeader
/// (cuisine, name, "Start cooking" / "Use in a meal"), PhotoStrip, the Facts card, the party and health ScoreCards, ingredients with servings, steps,
/// recipe pages and details. The toolbar has the favourite heart and the PageMenu,
/// whose recipe group gives the owner Generate photo / Edit / Delete.
struct RecipeDetailView: View {
    let recipeID: UUID
    var showCloseButton: Bool = false
    /// Scroll to the current party's note once it loads (opened from "View note on recipe").
    var focusPartyNote: Bool = false

    @Environment(FoodStore.self) var store
    @Environment(EntitlementStore.self) var entitlements
    @Environment(\.dismiss) var dismiss

    @State var fallbackRecipe: Recipe?
    @State var isLoadingRemote = false
    @State var showEditSheet = false
    @State var showMealEditor = false
    @State var selectedPhotoIndex: Int?
    @State var confirmDeleteRecipe = false
    @State var deleteError: String?
    @State var isAnalyzingHealth = false
    @State var healthAnalysisFailed = false
    @State var showHealthRationale = false
    @State var isGeneratingPhoto = false
    @State var showCookMode = false

    init(recipeID: UUID, showCloseButton: Bool = false, focusPartyNote: Bool = false) {
        self.recipeID = recipeID
        self.showCloseButton = showCloseButton
        self.focusPartyNote = focusPartyNote
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
                ScreenSkeleton(label: "Loading recipe")
            } else {
                EmptyState("Recipe is gone", message: "It was deleted.", layout: .screen)
                    .padding(.horizontal, DS.Spacing.gutter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DS.Color.bg)
            }
        }
        .screenTitle(showCloseButton ? (recipe?.name ?? "Recipe") : "", displayMode: .inline)
        .task { await loadRecipeAndHealth() }
        .task(id: recipeID) { await store.loadPartyRecipeNotes(dishID: recipeID) }
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
        .fullScreenCover(isPresented: $showCookMode) {
            if let recipe {
                CookModeView(recipe: recipe) { showMealEditor = true }
            }
        }
    }

    private func content(for recipe: Recipe) -> some View {
        let isOwner = recipe.ownerID == store.userID
        return ScrollViewReader { proxy in ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                RecipeDetailHeader(
                    recipe: recipe,
                    onStartCooking: { showCookMode = true },
                    onUseInMeal: { showMealEditor = true }
                )

                PhotoStrip(
                    photos: allPhotos.map { .remote(path: $0, bucket: SupabaseConfig.recipeBucket, cuisine: recipe.cuisine) },
                    onAddPhoto: isOwner ? { showEditSheet = true } : nil,
                    onSelect: { selectedPhotoIndex = $0 }
                )

                RecipeDetailFacts(recipe: recipe)

                RecipeScoreCards(
                    recipe: recipe,
                    isAnalyzingHealth: isAnalyzingHealth,
                    healthAnalysisFailed: healthAnalysisFailed,
                    onOpenHealth: { showHealthRationale = true }
                )

                PartyRecipeNoteCard(recipeID: recipe.id)
                    .id(Self.partyNoteAnchor)

                if !recipe.ingredients.isEmpty {
                    RecipeIngredientsCard(ingredients: recipe.ingredients, serves: recipe.serves)
                }

                if !recipe.instructions.isEmpty {
                    RecipeStepsCard(instructions: recipe.instructions)
                }

                if !recipe.recipePhotoPaths.isEmpty {
                    RecipePhotosCard(recipe: recipe)
                }

                RecipeDetailInfoCard(recipe: recipe)
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s12)
        }
        .background(DS.Color.bg)
        // Runs on appear too, so a note already in memory still gets scrolled to.
        .task(id: partyNoteLoaded) {
            guard focusPartyNote, partyNoteLoaded else { return }
            // Let the sheet finish presenting before scrolling.
            try? await Task.sleep(for: .milliseconds(Int(DS.Motion.durationLayout * 1000)))
            withAnimation(DS.Motion.layout) {
                proxy.scrollTo(Self.partyNoteAnchor, anchor: .top)
            }
        }
        }
    }

    private static let partyNoteAnchor = "partyNote"

    private var partyNoteLoaded: Bool {
        guard let party = store.currentParty else { return false }
        return store.partyRecipeNote(dishID: recipeID, partyID: party.id) != nil
    }
}

#Preview {
    NomNomPreview { store in
        if let firstRecipe = store.dishes.first {
            RecipeDetailView(recipeID: firstRecipe.id)
        }
    }
}
