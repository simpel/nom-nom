import SwiftUI

/// Clean, minimal list of recent search queries with one-tap recall and removal.
struct SearchHistorySection: View {
    @Bindable var historyStore = SearchHistoryStore.shared
    let onSelectQuery: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !historyStore.recentQueries.isEmpty {
                HStack {
                    Text("RECENT SEARCHES")
                        .font(.caption.weight(.semibold))
                        .tracking(0.5)
                        .foregroundStyle(DS.Color.textSecondary)

                    Spacer()

                    AppButton(
                        "Clear All",
                        variant: .neutral,
                        style: .ghost,
                        size: .sm
                    ) {
                        historyStore.clearAll()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(historyStore.recentQueries, id: \.self) { query in
                        HStack(spacing: 12) {
                            Button {
                                onSelectQuery(query)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .font(.subheadline)
                                        .foregroundStyle(DS.Color.textTertiary)

                                    Text(query)
                                        .font(.subheadline)
                                        .foregroundStyle(DS.Color.textPrimary)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                historyStore.removeQuery(query)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(DS.Color.textTertiary)
                                    .padding(8)
                            }
                            .accessibilityLabel("Remove \(query)")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if query != historyStore.recentQueries.last {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(DS.Color.panel)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.top, 60)

                    Text("Search Recipes")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("Find dishes by title, cuisine, or ingredients.")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    NomNomPreview {
        SearchHistorySection(onSelectQuery: { _ in })
    }
}
