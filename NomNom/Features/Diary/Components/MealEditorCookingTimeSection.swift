import SwiftUI

/// Section in MealEditorView for selecting cooking time / effort.
struct MealEditorCookingTimeSection: View {
    @Binding var effort: EffortLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "Cooking Time",
                trailingText: effort?.label,
                trailingColor: DS.Color.accentText,
                horizontalPadding: 4
            )
            CookingTimeSelector(selection: $effort)
        }
    }
}

