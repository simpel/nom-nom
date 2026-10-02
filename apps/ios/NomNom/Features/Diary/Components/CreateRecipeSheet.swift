import SwiftUI

/// Dedicated modal sheet for creating a new recipe with name, instructions, effort, and cuisine.
struct CreateRecipeSheet: View {
    var initialName: String = ""
    var initialCuisine: String? = nil
    var onCreated: ((Recipe) -> Void)?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var coverPhotosDraft = FoodStore.PhotosDraft()
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var navigateToDetails = false
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    AppButton(
                        "Scan Photos or Cookbook",
                        icon: "camera.viewfinder",
                        variant: .primary,
                        appearance: .outline,
                        fullWidth: true
                    ) {
                        showingScanner = true
                    }

                    RecipeBasicsForm(
                        name: $name,
                        coverPhotos: $coverPhotosDraft,
                        effort: $recipeDraft.effort,
                        cuisine: $recipeDraft.cuisine
                    )
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s11)
            }
            .background(DS.Color.sheet)
            .screenTitle("New Recipe", displayMode: .inline)
            .sheetNextToolbar(canProceed: !name.trimmedName.isEmpty) {
                navigateToDetails = true
            }
            .navigationDestination(isPresented: $navigateToDetails) {
                RecipeDetailsStepView(
                    name: name,
                    coverPhotosDraft: coverPhotosDraft,
                    recipeDraft: $recipeDraft,
                    onCreated: onCreated,
                    onDismiss: { dismiss() }
                )
            }
            .sheet(isPresented: $showingScanner) {
                RecipeScannerSheet { result, photoDataList in
                    applyParsedRecipe(result, photos: photoDataList)
                }
            }
            .onAppear {
                if name.isEmpty && !initialName.isEmpty {
                    name = initialName
                }
                if recipeDraft.cuisine == nil, let initialCuisine {
                    recipeDraft.cuisine = initialCuisine
                }
            }
        }
        .dsSheet()
    }

    private func applyParsedRecipe(_ result: ParsedRecipeResult, photos: [Data]) {
        if !result.name.isEmpty {
            name = result.name
        }
        if let cuisine = result.cuisine {
            recipeDraft.cuisine = cuisine
        }
        if let cuisineID = result.cuisineID {
            recipeDraft.cuisineID = cuisineID
        }
        if let cookingMethodID = result.cookingMethodID {
            recipeDraft.cookingMethodID = cookingMethodID
        }
        if let dishKindID = result.dishKindID {
            recipeDraft.dishKindID = dishKindID
        }
        if let effort = result.effort, let level = EffortLevel(rawValue: effort) {
            recipeDraft.effort = level
        }
        if let serves = result.serves {
            recipeDraft.serves = serves
        }
        recipeDraft.ingredients = result.ingredients
        recipeDraft.instructions = result.instructions

        // Attach scanned photos to drafts
        for photo in photos {
            recipeDraft.addPhotoData(photo)
        }

        navigateToDetails = true
    }
}
