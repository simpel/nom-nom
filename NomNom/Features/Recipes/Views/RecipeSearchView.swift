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
            .searchable(text: $searchText, prompt: "Search recipes, tags, or cuisines")
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

    // MARK: - Idle Search History View

    private var idleHistoryView: some View {
        ScrollView {
            SearchHistorySection { query in
                searchText = query
                SearchHistoryStore.shared.addQuery(query)
            }
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
    }

    // MARK: - Search Results View (2-Column Minimalist Grid)

    @ViewBuilder
    private var searchResultsView: some View {
        if rawSearchResults.isEmpty {
            ContentUnavailableView {
                Label("No matching recipes", systemImage: "magnifyingglass")
            } description: {
                Text("Try searching with a different term, ingredient, or cuisine.")
            } actions: {
                Button("Clear Search") {
                    searchText = ""
                }
                .buttonStyle(.bordered)
            }
        } else if displayedSearchResults.isEmpty {
            ContentUnavailableView {
                Label("No filtered results", systemImage: "line.3.horizontal.decrease")
            } description: {
                Text("No recipes match your current sort and filter criteria.")
            } actions: {
                Button("Reset Filters") {
                    filterCriteria = RecipeFilterCriteria()
                }
                .buttonStyle(.bordered)
            }
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
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    NomNomPreview {
        RecipeSearchView()
    }
}
