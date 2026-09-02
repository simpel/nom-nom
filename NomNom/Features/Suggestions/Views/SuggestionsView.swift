import SwiftUI

/// Tab 3 — what should we cook? Ranked by how much it was liked, how long ago we
/// had it, and how sure we are about it.
struct SuggestionsView: View {
    @Environment(FoodStore.self) private var store

    @State private var filters = SuggestionFilters()
    @State private var showMath = false
    @State private var sheet: SuggestionSheet?

    private var results: [Suggestion] {
        SuggestionEngine().rank(store.suggestionInputs, filters: filters)
    }

    private var allTags: [String] {
        Array(Set(store.myDishes.flatMap(\.tags))).sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.myDishes.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing to suggest yet", systemImage: "sparkles")
                    } description: {
                        Text("Log a few meals and this tab starts telling you what to cook next.")
                    }
                } else {
                    List {
                        Section {
                            modePicker
                            Text(filters.mode.explanation)
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        if results.isEmpty {
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No dish matches these filters.")
                                        .font(.subheadline)
                                    Button("Reset filters") {
                                        filters = SuggestionFilters(mode: filters.mode)
                                    }
                                    .font(.caption)
                                }
                            }
                        } else {
                            Section {
                                ForEach(Array(results.prefix(40).enumerated()), id: \.element.id) { entry in
                                    SuggestionRow(suggestion: entry.element,
                                                  rank: entry.offset + 1,
                                                  showScore: showMath)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            sheet = .cook(entry.element.dish.id)
                                        } label: {
                                            Label("Cook it", systemImage: "flame")
                                        }
                                        .tint(DS.Color.accent)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("\(results.count) options")
                                        .monospacedDigit()
                                    Spacer()
                                    Button(showMath ? "Hide scores" : "Show scores") {
                                        showMath.toggle()
                                    }
                                    .font(.caption)
                                    .textCase(nil)
                                }
                            } footer: {
                                Text("Swipe a row right to log it as tonight's dinner.")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(DS.Color.bg)
                    .searchable(text: $filters.searchText, prompt: "Filter by name")
                    .refreshable { await store.load() }
                }
            }
            .screenTitle("What to eat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sheet = .filters
                    } label: {
                        Image(systemName: filters.activeCount > 0
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters")
                }
            }
            .sheet(item: $sheet) { destination in
                switch destination {
                case .filters:
                    SuggestionFiltersView(filters: $filters,
                                          roster: store.raterRoster,
                                          tags: allTags)
                case .cook(let dishID):
                    MealEditorView(mealID: nil, prefilledDishID: dishID)
                }
            }
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $filters.mode) {
            ForEach(SuggestionMode.allCases) { mode in
                Text(mode.shortTitle).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}

enum SuggestionSheet: Identifiable {
    case filters
    case cook(UUID)

    var id: String {
        switch self {
        case .filters: return "filters"
        case .cook(let dishID): return dishID.uuidString
        }
    }
}

#Preview {
    NomNomPreview(inNavigationStack: false) {
        SuggestionsView()
    }
}

