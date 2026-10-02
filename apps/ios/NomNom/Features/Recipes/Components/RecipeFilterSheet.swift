import SwiftUI

/// Filter and sort criteria for the recipe catalog.
struct RecipeFilterCriteria: Equatable {
    enum SortOption: String, CaseIterable, Identifiable {
        case popular = "Most popular"
        case effort = "Lowest effort"
        case recent = "Recently cooked"
        case alphabetical = "A–Z"

        var id: String { rawValue }
    }

    /// README "Numbers are data": scores read as 0–100 integers.
    enum ScoreThreshold: String, CaseIterable, Identifiable {
        case any = "Any rating"
        case good = "Good (50+)"
        case great = "Great (70+)"
        case amazing = "Amazing (85+)"

        var id: String { rawValue }

        var minScore: Double? {
            switch self {
            case .any: return nil
            case .good: return 0.50
            case .great: return 0.70
            case .amazing: return 0.85
            }
        }
    }

    var sort: SortOption = .popular
    var effort: EffortLevel? = nil
    var scoreThreshold: ScoreThreshold = .any
    var onlyFavorites: Bool = false

    var isDefault: Bool {
        sort == .popular && effort == nil && scoreThreshold == .any && !onlyFavorites
    }
}

/// Filter sheet for the recipe catalog: sort order and filters as ListRows in list
/// Cards (native menu pickers in the trailing slot, a Toggle for favourites), and a
/// reset when anything differs from the defaults.
struct RecipeFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var criteria: RecipeFilterCriteria

    @State private var draft: RecipeFilterCriteria

    init(criteria: Binding<RecipeFilterCriteria>) {
        self._criteria = criteria
        self._draft = State(initialValue: criteria.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                DSSection("Sort order") {
                    Card(layout: .list) {
                        pickerRow("Sort by", selection: $draft.sort) {
                            ForEach(RecipeFilterCriteria.SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    }
                }

                DSSection("Filters") {
                    Card(layout: .list) {
                        pickerRow("Effort", selection: $draft.effort) {
                            Text("Any effort").tag(EffortLevel?.none)
                            ForEach(EffortLevel.allCases) { level in
                                Text(level.label).tag(Optional(level))
                            }
                        }
                        pickerRow("Minimum rating", selection: $draft.scoreThreshold) {
                            ForEach(RecipeFilterCriteria.ScoreThreshold.allCases) { threshold in
                                Text(threshold.rawValue).tag(threshold)
                            }
                        }
                        ListRow("Favourites only", trailing: .toggle($draft.onlyFavorites))
                    }
                }

                if !draft.isDefault {
                    AppButton("Reset to defaults", variant: .secondary, appearance: .ghost, fullWidth: true) {
                        draft = RecipeFilterCriteria()
                    }
                }
            }
            .screenTitle("Sort and filter", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: false,
                canSave: true,
                onCancel: { dismiss() },
                onSave: {
                    criteria = draft
                    dismiss()
                }
            )
        }
        .dsSheet()
    }

    /// A ListRow whose trailing slot is a native menu picker (a system menu, like
    /// `Menu`); the row title names it.
    private func pickerRow<Value: Hashable, Options: View>(
        _ title: String,
        selection: Binding<Value>,
        @ViewBuilder options: () -> Options
    ) -> ListRow {
        let picker = Picker(title, selection: selection, content: options)
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(DS.Color.primaryText)
        return ListRow(title, trailing: .view { picker })
    }
}

#Preview {
    NomNomPreview {
        RecipeFilterSheet(criteria: .constant(RecipeFilterCriteria()))
    }
}
