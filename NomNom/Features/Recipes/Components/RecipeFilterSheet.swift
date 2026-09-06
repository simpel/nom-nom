import SwiftUI

/// Filter and sort criteria for the recipe catalog.
struct RecipeFilterCriteria: Equatable {
    enum SortOption: String, CaseIterable, Identifiable {
        case popular = "Most Popular"
        case effort = "Lowest Effort"
        case recent = "Recently Cooked"
        case alphabetical = "A–Z"

        var id: String { rawValue }
    }

    enum ScoreThreshold: String, CaseIterable, Identifiable {
        case any = "Any Rating"
        case good = "Good (0.5+)"
        case great = "Great (0.7+)"
        case amazing = "Amazing (0.85+)"

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

/// Minimalist modal sheet for adjusting recipe sort order and filtering criteria.
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
            Form {
                Section {
                    Picker("Sort by", selection: $draft.sort) {
                        ForEach(RecipeFilterCriteria.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } header: {
                    Text("SORT ORDER")
                }

                Section {
                    Picker("Effort", selection: $draft.effort) {
                        Text("Any Effort").tag(EffortLevel?.none)
                        ForEach(EffortLevel.allCases) { level in
                            Text(level.label).tag(Optional(level))
                        }
                    }

                    Picker("Minimum Rating", selection: $draft.scoreThreshold) {
                        ForEach(RecipeFilterCriteria.ScoreThreshold.allCases) { threshold in
                            Text(threshold.rawValue).tag(threshold)
                        }
                    }

                    Toggle("Favourites Only", isOn: $draft.onlyFavorites)
                } header: {
                    Text("FILTERS")
                }

                if !draft.isDefault {
                    Section {
                        AppButton(
                            "Reset to Defaults",
                            variant: .neutral,
                            style: .ghost,
                            size: .md,
                            isFullWidth: true
                        ) {
                            draft = RecipeFilterCriteria()
                        }
                    }
                }
            }
            .screenTitle("Sort & Filter", displayMode: .inline)
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
    }
}

#Preview {
    NomNomPreview {
        RecipeFilterSheet(criteria: .constant(RecipeFilterCriteria()))
    }
}
