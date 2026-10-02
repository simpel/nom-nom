import SwiftUI

/// Section in the meal editor for attaching or editing a recipe (instructions and/or photos).
struct RecipeEditorSection: View {
    @Binding var draft: FoodStore.RecipeDraft

    @State private var previewIndex: Int?

    var body: some View {
        RecipeServingsSection(serves: $draft.serves)

        RecipeIngredientsEditorSection(ingredients: $draft.ingredients)

        RecipeInstructionsEditorSection(instructions: $draft.instructions)

        DSSection("Recipe Photos", trailing: "Optional") {
            PhotoStripEditor(recipeDraft: $draft) { index in
                previewIndex = index
            }
        }
        .sheet(item: Binding(
            get: { previewIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { previewIndex = $0?.index }
        )) { item in
            MediaViewerSheet(.recipeDraft(draft), startIndex: item.index, title: "Recipe Page")
        }
    }
}
