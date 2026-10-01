import SwiftUI

/// The health score's BottomSheet: SheetHero (score, verdict, the tier's meaning), then
/// the Pro-gated rationale, cooking-technique note and macronutrient breakdown.
struct RecipeHealthRationaleSheet: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.block) {
                    SheetHero(
                        score: Double(healthIndex.score) / 100,
                        verdict: healthIndex.verdict,
                        lead: healthIndex.tier.explanation
                    )

                    ProGate {
                        RecipeHealthDetailContent(healthIndex: healthIndex)
                    }
                }
                .padding(.horizontal, DS.Spacing.s5)
                .padding(.top, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s12)
            }
            .background(DS.Color.sheet)
            .screenTitle("Health score", displayMode: .inline)
            .sheetCancelToolbar()
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
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            Text(healthIndex.rationale)
                .textStyle(.sansMd)
                .fixedSize(horizontal: false, vertical: true)

            if let impact = healthIndex.breakdown?.cookingImpact, !impact.isEmpty {
                SectionCard("Cooking technique", layout: .inset) {
                    Text(impact)
                        .textStyle(.sansMd)
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
