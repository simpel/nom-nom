import SwiftUI

/// Category drill-down: a ScreenHeader with the category photo as its avatar and "Add
/// recipe" as the one action, then the recipes in a two-column grid.
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
                VStack(spacing: DS.Spacing.block) {
                    header.padding(.top, DS.Spacing.s5)

                    EmptyState(
                        "No \(displayName) recipes yet",
                        message: "Add a \(displayName) recipe and it will show up here.",
                        action: EmptyStateAction("Add recipe") { showingCreateSheet = true }
                    )
                    .padding(.horizontal, DS.Spacing.gutter)
                    Spacer(minLength: 0)
                }
            } else if displayedRecipes.isEmpty {
                VStack(spacing: DS.Spacing.block) {
                    header.padding(.top, DS.Spacing.s5)

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
                        header
                        MinimalRecipeGrid(recipes: displayedRecipes, title: "Recipes", onSelect: onSelectRecipe)
                    }
                    .padding(.top, DS.Spacing.s5)
                    .padding(.bottom, DS.Spacing.s11)
                }
            }
        }
        .background(DS.Color.bg)
        .screenTitle("", displayMode: .inline)
        .toolbar {
            // Navigation toolbars use system buttons (AppButton README "Rules").
            if !rawRecipes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    RecipeFilterToolbarButton(isFiltered: !filterCriteria.isDefault) {
                        showingFilterSheet = true
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                PageMenu { categoryMenu }
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

    /// The page menu's category group: Rename and Delete, for custom categories only.
    @ViewBuilder
    private var categoryMenu: some View {
        if isCustomCategory, let record = categoryRecord {
            Section {
                Button("Rename category", systemImage: "pencil") {
                    newCategoryName = record.name
                    showingRenameAlert = true
                }
                Button("Delete category", systemImage: "trash", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }
        }
    }

    /// The screen's one header: the category photo as the `xl` avatar, "Add recipe" as the action.
    private var header: some View {
        ScreenHeader(
            displayName,
            eyebrow: "Recipes",
            avatar: Avatar(category: currentCategoryItem, size: .xl, decorative: true),
            // An empty category's EmptyState already carries "Add recipe".
            actions: rawRecipes.isEmpty ? [] : [ScreenHeaderAction(title: "Add recipe") { showingCreateSheet = true }]
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
