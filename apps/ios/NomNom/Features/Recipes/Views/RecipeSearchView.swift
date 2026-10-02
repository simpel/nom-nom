import SwiftUI

/// Dedicated Search tab screen.
/// Surfaces search history when idle, and a minimalist 2-column gallery for live query results.
struct RecipeSearchView: View {
    @Environment(FoodStore.self) private var store

    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var filterCriteria = RecipeFilterCriteria()

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var rawSearchResults: [Recipe] {
        guard !trimmedSearch.isEmpty else { return [] }
        let suggestions = DishRepository.suggestions(
            for: trimmedSearch,
            in: store.recipes,
            history: store.dishHistory,
            favoriteIDs: store.favoriteRecipeIDs,
            limit: 50
        )
        return suggestions.compactMap { store.recipe($0.dishID) }
    }

    private var displayedSearchResults: [Recipe] {
        RecipeFilterEngine.apply(
            criteria: filterCriteria,
            to: rawSearchResults,
            store: store
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if !trimmedSearch.isEmpty {
                    searchResultsView
                } else {
                    idleHistoryView
                }
            }
            .background(DS.Color.bg)
            .screenTitle("Search")
            .searchable(text: $searchText, prompt: "Search recipes, ingredients, or cuisines")
            .onSubmit(of: .search) {
                SearchHistoryStore.shared.addQuery(trimmedSearch)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: filterCriteria.isDefault
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("Sort and Filter")
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                RecipeFilterSheet(criteria: $filterCriteria)
            }
        }
    }

    // MARK: - Idle Search View

    private var idleHistoryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.sectionLarge) {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    RecommendedForYouShelf()
                    RecipeShelf("Last used recipes", recipes: store.recentRecipes) { RecipeDetailView(recipe: $0) }
                    RecipeShelf("Favourites", recipes: store.favoriteRecipes) { RecipeDetailView(recipe: $0) }
                    RecipeShelf("Popular recipes", recipes: store.popularRecipes) { RecipeDetailView(recipe: $0) }
                }
                .padding(.horizontal, DS.Spacing.gutter)

                SearchHistorySection(
                    showsEmptyState: store.recentRecipes.isEmpty && store.favoriteRecipes.isEmpty && store.popularRecipes.isEmpty
                ) { query in
                    searchText = query
                    SearchHistoryStore.shared.addQuery(query)
                }
            }
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
    }

    // MARK: - Search Results View (2-Column Minimalist Grid)

    @ViewBuilder
    private var searchResultsView: some View {
        if rawSearchResults.isEmpty {
            // README cases "Search found nothing" and "Filters found nothing": the whole
            // results view is empty, so `screen`.
            EmptyState(
                "No recipes match \u{2018}\(trimmedSearch)\u{2019}",
                message: "Try a shorter search, an ingredient or a cuisine.",
                icon: "magnifyingglass",
                layout: .screen,
                action: EmptyStateAction("Clear search", variant: .secondary) { searchText = "" }
            )
            .padding(.horizontal, DS.Spacing.gutter)
        } else if displayedSearchResults.isEmpty {
            EmptyState(
                "Nothing with these filters",
                message: "Effort and rating narrow the list the most.",
                layout: .screen,
                action: EmptyStateAction("Clear filters", variant: .secondary) {
                    filterCriteria = RecipeFilterCriteria()
                }
            )
            .padding(.horizontal, DS.Spacing.gutter)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    searchSubHeader
                    MinimalRecipeGrid(recipes: displayedSearchResults, onNavigate: { _ in
                        SearchHistoryStore.shared.addQuery(trimmedSearch)
                    })
                }
                .padding(.top, DS.Spacing.sm)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
        }
    }

    private var searchSubHeader: some View {
        HStack {
            Text("\(displayedSearchResults.count) result\(displayedSearchResults.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(DS.Color.textSecondary)

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.vertical, DS.Spacing.s1)
    }
}

#Preview {
    NomNomPreview {
        RecipeSearchView()
    }
}
