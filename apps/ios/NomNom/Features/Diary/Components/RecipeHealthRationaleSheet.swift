import SwiftUI

/// The health score's BottomSheet ("Nom Nom iOS" canvas, HealthSheet): SheetHero
/// (score, verdict, the tier's meaning), then a ProCard "Why it scores 72" with the
/// rationale, cooking technique, macronutrients and the highlights / watch-outs, and a
/// ghost "How this score is calculated" outside the gate.
struct RecipeHealthRationaleSheet: View {
    let recipe: Recipe
    let healthIndex: HealthIndex

    @State private var showingExplainer = false

    var body: some View {
        NavigationStack {
            SheetBody {
                SheetHero(
                    score: Double(healthIndex.score) / 100,
                    verdict: healthIndex.verdict,
                    lead: healthIndex.tier.explanation,
                    ink: .pro
                )

                ProCard(
                    "Why it scores \(healthIndex.score)",
                    teaser: "See the full reasoning, the cooking technique, macros per serving and what to watch out for."
                ) {
                    RecipeHealthDetailContent(healthIndex: healthIndex)
                }

                AppButton("How this score is calculated", variant: .secondary, appearance: .ghost, size: .sm) {
                    showingExplainer = true
                }
            }
            .screenTitle("Health score", displayMode: .inline)
            .sheetCloseToolbar()
            .sheet(isPresented: $showingExplainer) {
                RecipeHealthExplainerSheet()
            }
        }
        .dsSheet(detents: [.fraction(0.85), .large])
    }
}
