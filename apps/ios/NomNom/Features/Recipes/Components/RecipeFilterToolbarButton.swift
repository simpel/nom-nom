import SwiftUI

/// The toolbar control that opens `RecipeFilterSheet` (search tab, category drill-down).
/// A system toolbar button (AppButton README: sheet and navigation toolbars use system
/// buttons); the filled glyph marks filters that are on.
struct RecipeFilterToolbarButton: View {
    let isFiltered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFiltered
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Sort and filter")
        .accessibilityValue(isFiltered ? "Filtered" : "")
        .barItemStyle()
    }
}
