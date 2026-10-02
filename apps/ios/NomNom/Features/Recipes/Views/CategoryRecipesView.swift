import SwiftUI

/// Category drill-down screen displaying recipes in an ultra-minimalist 2-column grid.
struct CategoryRecipesView: View {
    let categoryName: String
    let displayName: String
    var onSelectRecipe: ((Recipe) -> Void)? = nil

    init(cuisine: Cuisine, onSelectRecipe: ((Recipe) -> Void)? = nil) {
        self.categoryName = cuisine.rawValue
        self.displayName = cuisine.displayName
        self.onSelectRecipe = onSelectRecipe
    }

    init(category: CategoryItem, onSelectRecipe: ((Recipe) -> Void)? = nil) {
        self.categoryName = category.name
        self.displayName = category.displayName
        self.onSelectRecipe = onSelectRecipe
    }

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateSheet = false
    @State private var showingFilterSheet = false
    @State private var filterCriteria = RecipeFilterCriteria()
    @State private var showingRenameAlert = false
    @State private var newCategoryName = ""
    @State private var showingDeleteConfirm = false

    private var categoryRecord: CategoryRecord? {
        store.categories.first { $0.slug.lowercased() == categoryName.lowercased() }
    }

    private var isCustomCategory: Bool {
        Cuisine.matching(from: categoryName) == nil
    }

    private var currentCategoryItem: CategoryItem {
        store.allCategories.first { $0.id == categoryName.lowercased() }
            ?? CategoryItem(name: categoryName, photoPath: store.categoryPhotoPaths[categoryName.lowercased()])
    }

    private var rawRecipes: [Recipe] {
        store.recipes(inCategory: categoryName)
    }

    private var displayedRecipes: [Recipe] {
        RecipeFilterEngine.apply(
            criteria: filterCriteria,
            to: rawRecipes,
            store: store
        )
    }

    var body: some View {
        Group {
            if rawRecipes.isEmpty {
                VStack(spacing: DS.Spacing.s4) {
                    heroCover(count: 0)
                        .padding(.top, DS.Spacing.s3)

                    EmptyState(
                        "No \(displayName) recipes yet",
                        message: "Add a \(displayName) recipe and it will show up here.",
                        action: EmptyStateAction("Add recipe") { showingCreateSheet = true }
                    )
                    .padding(.horizontal, DS.Spacing.gutter)
                    Spacer(minLength: 0)
                }
            } else if displayedRecipes.isEmpty {
                VStack(spacing: DS.Spacing.s4) {
                    heroCover(count: rawRecipes.count)
                        .padding(.top, DS.Spacing.s3)

                    // README case "Filters found nothing".
                    EmptyState(
                        "Nothing with these filters",
                        message: "Effort and rating narrow the list the most.",
                        action: EmptyStateAction("Clear filters", variant: .secondary) {
                            filterCriteria = RecipeFilterCriteria()
                        }
                    )
                    .padding(.horizontal, DS.Spacing.gutter)
                    Spacer(minLength: 0)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.block) {
                        heroCover(count: rawRecipes.count)
                        MinimalRecipeGrid(recipes: displayedRecipes, title: "Recipes", onSelect: onSelectRecipe)
                    }
                    .padding(.top, DS.Spacing.s3)
                    .padding(.bottom, DS.Spacing.s11)
                }
            }
        }
        .background(DS.Color.bg)
        .screenTitle(displayName)
        .toolbar {
            // Navigation toolbars use system buttons (AppButton README "Rules").
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Add recipe", systemImage: "plus") {
                    showingCreateSheet = true
                }

                if !rawRecipes.isEmpty {
                    RecipeFilterToolbarButton(isFiltered: !filterCriteria.isDefault) {
                        showingFilterSheet = true
                    }
                }

                if isCustomCategory, categoryRecord != nil {
                    Menu {
                        Button {
                            if let record = categoryRecord {
                                newCategoryName = record.name
                                showingRenameAlert = true
                            }
                        } label: {
                            Label("Rename category", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete category", systemImage: "trash")
                        }
                    } label: {
                        Label("Category options", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Rename category", isPresented: $showingRenameAlert) {
            TextField("Category name", text: $newCategoryName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let record = categoryRecord, !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task {
                        try? await store.updateCategory(id: record.id, newName: newCategoryName)
                    }
                }
            }
        } message: {
            Text("Renaming this kitchen category will update its recipes and regenerate its theme photo.")
        }
        .confirmationDialog(
            "Delete category?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete category and photo", role: .destructive) {
                if let record = categoryRecord {
                    Task {
                        try? await store.deleteCategory(id: record.id)
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes the category and removes its generated photograph from storage.")
        }
        .sheet(isPresented: $showingFilterSheet) {
            RecipeFilterSheet(criteria: $filterCriteria)
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateRecipeSheet(initialCuisine: categoryName) { newRecipe in
                onSelectRecipe?(newRecipe)
            }
        }
    }

    /// The category's cover: a LabeledPhotoCard `lg` `landscape` across the gutter
    /// (LabeledPhotoCard README: "Replaces … CategoryHeroCoverCard"; see DS-GAPS.md).
    private func heroCover(count: Int) -> some View {
        LabeledPhotoCard(
            .category(currentCategoryItem),
            label: displayName,
            meta: CategoryItem.recipeCountText(count),
            size: .lg,
            format: .landscape,
            fillsWidth: true
        )
        .padding(.horizontal, DS.Spacing.gutter)
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            CategoryRecipesView(cuisine: .italian)
        }
    }
}
