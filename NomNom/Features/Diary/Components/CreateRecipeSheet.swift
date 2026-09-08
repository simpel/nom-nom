import SwiftUI

/// Dedicated modal sheet for creating a new recipe with name, instructions, effort, and tags.
struct CreateRecipeSheet: View {
    var initialName: String = ""
    var initialCuisine: String? = nil
    var onCreated: ((Recipe) -> Void)?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var coverPhotosDraft = FoodStore.PhotosDraft()
    @State private var recipeDraft = FoodStore.RecipeDraft()
    @State private var tagsText: String = ""
    @State private var navigateToDetails = false
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    AppButton(
                        "Scan Photos or Cookbook",
                        systemImage: "camera.viewfinder",
                        variant: .secondary,
                        style: .outlined,
                        size: .md,
                        isFullWidth: true
                    ) {
                        showingScanner = true
                    }

                    AssetPhotosPickerSection(draft: $coverPhotosDraft, title: "Cover Photo")

                    SectionCard("Recipe Name") {
                        Input("Recipe name (e.g. Carbonara)", text: $name)
                            .autocorrectionDisabled()
                    }

                    SectionCard("Cooking Effort") {
                        TactileOptionPicker(selection: $recipeDraft.effort)
                    }

                    CuisinePickerSection(selection: $recipeDraft.cuisine)
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("New Recipe", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") {
                        navigateToDetails = true
                    }
                    .disabled(name.trimmedName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .navigationDestination(isPresented: $navigateToDetails) {
                RecipeDetailsStepView(
                    name: name,
                    coverPhotosDraft: coverPhotosDraft,
                    recipeDraft: $recipeDraft,
                    tagsText: $tagsText,
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
    }

    private func applyParsedRecipe(_ result: ParsedRecipeResult, photos: [Data]) {
        if !result.name.isEmpty {
            name = result.name
        }
        if let cuisine = result.cuisine {
            recipeDraft.cuisine = cuisine
        }
        if let effort = result.effort, let level = EffortLevel(rawValue: effort) {
            recipeDraft.effort = level
        }
        if let serves = result.serves {
            recipeDraft.serves = serves
        }
        recipeDraft.ingredients = result.ingredients
        recipeDraft.instructions = result.instructions
        if !result.tags.isEmpty {
            tagsText = result.tags.joined(separator: ", ")
        }

        // Attach scanned photos to drafts
        for (index, photo) in photos.enumerated() {
            if index == 0 && coverPhotosDraft.isEmpty {
                coverPhotosDraft.append(photo)
            } else {
                recipeDraft.addPhotoData(photo)
            }
        }

        navigateToDetails = true
    }
}
