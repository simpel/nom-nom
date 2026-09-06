import SwiftUI

/// Dedicated modal sheet for selecting cuisines/categories for a recipe.
/// Displays all cuisine categories in a 2-column grid matching the discovery experience,
/// supporting multi-selection and atomic commit/discard actions.
struct CuisinePickerSheet: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: String?

    @State private var draftSelection: Set<String>
    @State private var customText: String

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(selection: Binding<String?>) {
        self._selection = selection
        let initialParts = Cuisine.parseMultiple(from: selection.wrappedValue)
        let presetMatches = initialParts.compactMap { part -> String? in
            guard let matched = Cuisine.matching(from: part) else { return nil }
            return matched.rawValue.lowercased()
        }
        let customMatches = initialParts.filter { Cuisine.matching(from: $0) == nil }

        self._draftSelection = State(initialValue: Set(presetMatches))
        self._customText = State(initialValue: customMatches.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: categoryColumns, spacing: 12) {
                        ForEach(Cuisine.allCases) { cuisine in
                            let isSelected = draftSelection.contains(cuisine.rawValue.lowercased())
                            let count = store.recipeCount(forCategory: cuisine.rawValue)

                            Button {
                                toggleSelection(for: cuisine)
                            } label: {
                                CategoryGridCard(
                                    cuisine: cuisine,
                                    count: count,
                                    isSelected: isSelected
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SectionCard("Other / Custom Kitchen") {
                        Input("e.g. Ethiopian, Lebanese, Jamaican", text: $customText)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(DS.Color.bg)
            .screenTitle("Kitchen / Cuisine", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: false,
                canSave: true,
                onCancel: {
                    dismiss()
                },
                onSave: {
                    saveSelection()
                    dismiss()
                }
            )
        }
    }

    private func toggleSelection(for cuisine: Cuisine) {
        let key = cuisine.rawValue.lowercased()
        if draftSelection.contains(key) {
            draftSelection.remove(key)
        } else {
            draftSelection.insert(key)
        }
    }

    private func saveSelection() {
        var results: [String] = []

        // Maintain canonical ordering according to Cuisine.allCases
        for cuisine in Cuisine.allCases {
            if draftSelection.contains(cuisine.rawValue.lowercased()) {
                results.append(cuisine.rawValue)
            }
        }

        let customParts = Cuisine.parseMultiple(from: customText)
        for part in customParts {
            if !results.contains(where: { $0.lowercased() == part.lowercased() }) {
                results.append(part)
            }
        }

        if results.isEmpty {
            selection = nil
        } else {
            selection = results.joined(separator: ", ")
        }
    }
}

#Preview {
    NomNomPreview {
        CuisinePickerSheet(selection: .constant("italian, mexican"))
    }
}
