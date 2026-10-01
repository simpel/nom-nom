// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// Step 1 of the recipe create and edit sheets: cover photos, the recipe name
/// (a `plain` Input in a SectionCard), cooking time and cuisine.
struct RecipeBasicsForm: View {
    @Binding var name: String
    @Binding var coverPhotos: FoodStore.PhotosDraft
    @Binding var effort: EffortLevel?
    @Binding var cuisine: String?

    var body: some View {
        AssetPhotosPickerSection(draft: $coverPhotos, title: "Cover Photo")

        SectionCard("Recipe Name") {
            Input("Recipe name (e.g. Carbonara)", text: $name, appearance: .plain)
                .autocorrectionDisabled()
        }

        MealEditorCookingTimeSection(effort: $effort)

        CuisinePickerSection(selection: $cuisine)
    }
}

private struct RecipeBasicsFormPreview: View {
    @State private var name = ""
    @State private var photos = FoodStore.PhotosDraft()
    @State private var effort: EffortLevel?
    @State private var cuisine: String? = "italian"

    var body: some View {
        NomNomPreview(inNavigationStack: false) { _ in
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    RecipeBasicsForm(name: $name, coverPhotos: $photos, effort: $effort, cuisine: $cuisine)
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { RecipeBasicsFormPreview() }
#Preview("Dark") { RecipeBasicsFormPreview().preferredColorScheme(.dark) }
