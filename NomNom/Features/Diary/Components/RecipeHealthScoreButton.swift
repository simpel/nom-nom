import SwiftUI

/// Wrapper struct to ensure sheet is only presented with non-nil payload
struct RecipeHealthSheetPayload: Identifiable {
    let id = UUID()
    let recipe: Recipe
    let healthIndex: HealthIndex
}

/// Compact "Details" accessory, embedded as the trailing slot of the health score's
/// `DividedScoreCard`. Tapping presents the full rationale sheet.
struct RecipeHealthDetailsButton: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    @State private var presentedPayload: RecipeHealthSheetPayload?

    var body: some View {
        AppButton(
            icon: .system("info.circle"),
            variant: .neutral,
            style: .ghost,
            size: .sm
        ) {
            presentedPayload = RecipeHealthSheetPayload(recipe: recipe, healthIndex: healthIndex)
        }
        .accessibilityLabel("Health score details")
        .sheet(item: $presentedPayload) { payload in
            RecipeHealthRationaleSheet(recipe: payload.recipe, healthIndex: payload.healthIndex)
        }
    }
}
