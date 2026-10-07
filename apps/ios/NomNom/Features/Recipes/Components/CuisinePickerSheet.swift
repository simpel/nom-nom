import SwiftUI

/// Dedicated modal sheet for selecting cuisines/categories for a recipe.
/// Displays all cuisine categories in a 2-column grid matching the discovery experience,
/// supporting multi-selection and atomic commit/discard actions.
struct CuisinePickerSheet: View {
    @Environment(FoodStore.self) private var store

    @Binding var selection: String?

    @State private var session: FormSession<CuisineSelection>

    private let categoryColumns = [
        GridItem(.flexible(), spacing: DS.Spacing.s3),
        GridItem(.flexible(), spacing: DS.Spacing.s3)
    ]

    init(selection: Binding<String?>) {
        self._selection = selection
        self._session = State(initialValue: FormSession(CuisineSelection(selection.wrappedValue)))
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                LazyVGrid(columns: categoryColumns, spacing: DS.Spacing.s3) {
                    ForEach(store.allCategories) { category in
                        LabeledPhotoCard(
                            .category(category),
                            label: category.displayName,
                            meta: CategoryItem.recipeCountText(store.recipeCount(forCategory: category.name)),
                            fillsWidth: true,
                            selected: session.form.contains(category.name)
                        ) {
                            session.form.toggle(category.name)
                        }
                    }
                }

                SectionCard("Other cuisine") {
                    Input("e.g. Ethiopian, Lebanese, Jamaican", text: $session.form.customText, appearance: .plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
            }
            .screenTitle("Cuisine", displayMode: .inline)
            .sheetCommitToolbar(session) { selection = $0.value }
        }
        .editorSheet(session)
    }
}

#Preview {
    NomNomPreview {
        CuisinePickerSheet(selection: .constant("italian, mexican"))
    }
}
