import SwiftUI

/// The health score's BottomSheet: SheetHero (score, verdict, the tier's meaning), then
/// the Pro-gated rationale, cooking-technique note and macronutrient breakdown.
struct RecipeHealthRationaleSheet: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    var body: some View {
        NavigationStack {
            SheetBody {
                SheetHero(
                    score: Double(healthIndex.score) / 100,
                    verdict: healthIndex.verdict,
                    lead: healthIndex.tier.explanation
                )

                ProGate {
                    RecipeHealthDetailContent(healthIndex: healthIndex)
                }
            }
            .screenTitle("Health score", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: [.fraction(0.85), .large])
    }
}

/// Rationale, cooking technique impact and macronutrients for a recipe's health
/// score. Used inside `RecipeHealthRationaleSheet`.
struct RecipeHealthDetailContent: View {
    let healthIndex: HealthIndex

    @State private var showingExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s6) {
            Text(healthIndex.rationale)
                .textStyle(.sansMd)
                .fixedSize(horizontal: false, vertical: true)

            if let impact = healthIndex.breakdown?.cookingImpact, !impact.isEmpty {
                SectionCard("Cooking technique") {
                    // SectionCard README: "`sans-md` `text-secondary` for prose".
                    Text(impact)
                        .textStyle(.sansMd, tone: .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let breakdown = healthIndex.breakdown,
               breakdown.macros != nil || !breakdown.positives.isEmpty {
                HealthMacroDistributionCard(macros: breakdown.macros, positives: breakdown.positives)
            }

            AppButton("How this score is calculated", variant: .secondary, appearance: .ghost, size: .sm) {
                showingExplainer = true
            }
        }
        .sheet(isPresented: $showingExplainer) {
            RecipeHealthExplainerSheet()
        }
    }
}
