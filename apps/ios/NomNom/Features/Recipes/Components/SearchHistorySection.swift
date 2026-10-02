import SwiftUI

/// Recent search queries as ListRows (tap to search again, ✕ to remove, a last
/// "Clear all" row), or an EmptyState inviting a first search.
struct SearchHistorySection: View {
    @Bindable var historyStore = SearchHistoryStore.shared
    var showsEmptyState: Bool = true
    let onSelectQuery: (String) -> Void

    var body: some View {
        if !historyStore.recentQueries.isEmpty {
            DSSection("Recent searches") {
                Card(layout: .list) {
                    ForEach(historyStore.recentQueries, id: \.self) { query in
                        ListRow(
                            query,
                            leading: .icon("clock"),
                            trailingAction: ListRowIconAction(
                                icon: "xmark",
                                accessibilityLabel: "Remove \(query)",
                                variant: .secondary
                            ) { historyStore.removeQuery(query) },
                            chevron: false
                        ) {
                            onSelectQuery(query)
                        }
                    }
                    ListRow("Clear all", chevron: false, tone: .destructive) {
                        historyStore.clearAll()
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.gutter)
        } else if showsEmptyState {
            EmptyState(
                "Search your recipes",
                message: "Find dishes by name, cuisine or ingredient.",
                icon: "magnifyingglass"
            )
            .padding(.horizontal, DS.Spacing.gutter)
        }
    }
}

#Preview {
    NomNomPreview {
        SearchHistorySection(onSelectQuery: { _ in })
    }
}
