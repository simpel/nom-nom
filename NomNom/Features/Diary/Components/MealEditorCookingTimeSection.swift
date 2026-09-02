import SwiftUI

/// Section in MealEditorView for selecting cooking time / effort.
struct MealEditorCookingTimeSection: View {
    @Binding var effort: EffortLevel?

    var body: some View {
        SectionCard("Cooking Time") {
            TactileOptionPicker(selection: $effort)
        }
    }
}
