import SwiftUI

/// Section in MealEditorView for selecting cooking time / effort.
struct MealEditorCookingTimeSection: View {
    @Binding var effort: EffortLevel?

    var body: some View {
        DSSection("Cooking Time", trailing: effort?.label, trailingTone: .primary) {
            CookingTimeSelector(selection: $effort)
        }
    }
}
