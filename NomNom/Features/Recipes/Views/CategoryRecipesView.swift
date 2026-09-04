import SwiftUI

/// Category drill-down screen displaying recipes in an ultra-minimalist 2-column grid.
struct CategoryRecipesView: View {
    let cuisine: Cuisine
    var onSelectRecipe: ((Recipe) -> Void)? = nil

    @Environment(FoodStore.self) private var store
    @State private var showingCreateSheet = false
    @State private var showingFilterSheet = false
    @State private var filterCriteria = RecipeFilterCriteria()

    private var rawRecipes: [Recipe] {
        store.recipes(inCategory: cuisine.rawValue)
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
                ContentUnavailableView {
                    Label("No \(cuisine.displayName) recipes", systemImage: "fork.knife")
                } description: {
                    Text("Add a new recipe tagged with \(cuisine.displayName) to see it here.")
                } actions: {
                    Button("Create Recipe") {
                        showingCreateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if displayedRecipes.isEmpty {
                ContentUnavailableView {
                    Label("No matching recipes", systemImage: "line.3.horizontal.decrease")
                } description: {
                    Text("Try loosening your effort or rating filters.")
                } actions: {
                    Button("Reset Filters") {
                        filterCriteria = RecipeFilterCriteria()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        subHeader
                        MinimalRecipeGrid(recipes: displayedRecipes, onSelect: onSelectRecipe)
                    }
                    .padding(.top, DS.Spacing.sm)
                    .padding(.bottom, DS.Spacing.screenBottom)
                }
            }
        }
        .background(DS.Color.bg)
        .screenTitle(cuisine.displayName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Create Recipe")
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            RecipeFilterSheet(criteria: $filterCriteria)
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateRecipeSheet(initialCuisine: cuisine.rawValue) { newRecipe in
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

            Button {
                showingFilterSheet = true
            } label: {
                HStack(spacing: 5) {
                    Text(filterCriteria.isDefault ? "Sort & Filter" : "Filtered")
                        .font(.caption.weight(.semibold))
                    if !filterCriteria.isDefault {
                        Circle()
                            .fill(DS.Color.accent)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundStyle(filterCriteria.isDefault ? DS.Color.textSecondary : DS.Color.accentText)
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
