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
                VStack(spacing: DS.Spacing.md) {
                    CategoryHeroCoverCard(category: currentCategoryItem, count: 0)
                        .padding(.top, DS.Spacing.sm)

                    ContentUnavailableView {
                        Label("No \(displayName) recipes", systemImage: "fork.knife")
                    } description: {
                        Text("Add a new recipe tagged with \(displayName) to see it here.")
                    } actions: {
                        AppButton("Create Recipe", variant: .primary, style: .normal, size: .md) {
                            showingCreateSheet = true
                        }
                    }
                }
            } else if displayedRecipes.isEmpty {
                VStack(spacing: DS.Spacing.md) {
                    CategoryHeroCoverCard(category: currentCategoryItem, count: rawRecipes.count)
                        .padding(.top, DS.Spacing.sm)

                    ContentUnavailableView {
                        Label("No matching recipes", systemImage: "line.3.horizontal.decrease")
                    } description: {
                        Text("Try loosening your effort or rating filters.")
                    } actions: {
                        AppButton("Reset Filters", variant: .neutral, style: .outlined, size: .md) {
                            filterCriteria = RecipeFilterCriteria()
                        }
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        CategoryHeroCoverCard(category: currentCategoryItem, count: rawRecipes.count)
                        subHeader
                        MinimalRecipeGrid(recipes: displayedRecipes, onSelect: onSelectRecipe)
                    }
                    .padding(.top, DS.Spacing.sm)
                    .padding(.bottom, DS.Spacing.screenBottom)
                }
            }
        }
        .background(DS.Color.bg)
        .screenTitle(displayName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                AppButton(systemImage: "plus", variant: .primary, style: .ghost, size: .sm) {
                    showingCreateSheet = true
                }
                .accessibilityLabel("Create Recipe")

                if isCustomCategory, categoryRecord != nil {
                    Menu {
                        Button {
                            if let record = categoryRecord {
                                newCategoryName = record.name
                                showingRenameAlert = true
                            }
                        } label: {
                            Label("Rename Category", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete Category", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body.weight(.medium))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
        }
        .alert("Rename Category", isPresented: $showingRenameAlert) {
            TextField("Category Name", text: $newCategoryName)
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
            "Delete Category?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Category & Photo", role: .destructive) {
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

    private var subHeader: some View {
        HStack {
            Text("\(displayedRecipes.count) recipe\(displayedRecipes.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(DS.Color.textSecondary)

            Spacer()

            AppButton(
                filterCriteria.isDefault ? "Sort & Filter" : "Filtered",
                variant: filterCriteria.isDefault ? .neutral : .primary,
                style: .ghost,
                size: .sm
            ) {
                showingFilterSheet = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    NomNomPreview {
        NavigationStack {
            CategoryRecipesView(cuisine: .italian)
        }
    }
}
