import SwiftUI

/// Searchable sheet to pick an existing recipe or type a new recipe name.
struct RecipePickerSheet: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var onSelectExistingRecipe: (Recipe) -> Void
    var onSelectNewRecipe: (String) -> Void

    init(onSelectExistingRecipe: @escaping (Recipe) -> Void, onSelectNewRecipe: @escaping (String) -> Void) {
        self.onSelectExistingRecipe = onSelectExistingRecipe
        self.onSelectNewRecipe = onSelectNewRecipe
    }

    // Compatibility init
    init(onSelectExistingDish: @escaping (Recipe) -> Void, onSelectNewDish: @escaping (String) -> Void) {
        self.onSelectExistingRecipe = onSelectExistingDish
        self.onSelectNewRecipe = onSelectNewDish
    }

    @State private var searchText = ""
    @State private var showingCreateRecipeSheet = false

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var suggestions: [DishRepository.NameSuggestion] {
        DishRepository.suggestions(for: searchText,
                                   in: store.recipes,
                                   history: store.dishHistory,
                                   limit: 25)
    }

    private var exactMatchExists: Bool {
        let key = trimmedSearch.normalizedForMatching
        guard !key.isEmpty else { return false }
        return store.recipes.contains { $0.normalizedName == key }
    }

    var body: some View {
        NavigationStack {
            List {
                if !trimmedSearch.isEmpty && !exactMatchExists {
                    Section {
                        Button {
                            onSelectNewRecipe(trimmedSearch)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add “\(trimmedSearch)”")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("Create as a new recipe")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !suggestions.isEmpty {
                    Section(trimmedSearch.isEmpty ? "Recent & Frequent Recipes" : "Matching Recipes") {
                        ForEach(suggestions) { suggestion in
                            if let recipe = store.recipe(suggestion.dishID) {
                                Button {
                                    onSelectExistingRecipe(recipe)
                                    dismiss()
                                } label: {
                                    recipeRow(recipe: recipe, suggestion: suggestion)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if trimmedSearch.isEmpty && store.myRecipes.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No recipes yet", systemImage: "fork.knife")
                        } description: {
                            Text("Type the name of what you cooked to create your first recipe.")
                        }
                    }
                }
            }
            .navigationTitle("Pick a Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search or type new recipe")
            .sheetCancelToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateRecipeSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Create Recipe")
                }
            }
            .sheet(isPresented: $showingCreateRecipeSheet) {
                CreateRecipeSheet(initialName: trimmedSearch) { newRecipe in
                    onSelectExistingRecipe(newRecipe)
                    dismiss()
                }
            }
        }
    }

    private func recipeRow(recipe: Recipe, suggestion: DishRepository.NameSuggestion) -> some View {
        let photos = store.photos(for: recipe)

        return HStack(spacing: 12) {
            if !photos.isEmpty {
                MiniPhotoArcDeck(
                    photoPaths: photos,
                    cardWidth: 42,
                    cardHeight: 54,
                    cornerRadius: AppRadius.photo
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    if let cuisine = Cuisine.formatDisplayName(recipe.cuisine) {
                        Text(cuisine)
                            .fontWeight(.medium)
                            .foregroundStyle(.tint)
                    }

                    if suggestion.timesServed > 0 {
                        if recipe.cuisine != nil { Text("•") }
                        Text("\(suggestion.timesServed)× cooked")
                    }
                    if let last = suggestion.lastServed {
                        Text("•")
                        let days = Int(Date.now.timeIntervalSince(last) / 86_400)
                        Text(days <= 0 ? "today" : "\(days)d ago")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.joined(separator: " • "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

typealias DishPickerSheet = RecipePickerSheet
