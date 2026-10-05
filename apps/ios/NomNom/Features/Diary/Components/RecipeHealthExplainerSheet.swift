import SwiftUI

/// How the 1–100 Recipe Health Index is calculated: the tiers, why cooking matters,
/// the research behind it and a guidance note. Based on validated nutritional
/// profiling frameworks (Food Compass and the Healthy Cooking Index).
struct RecipeHealthExplainerSheet: View {
    var body: some View {
        NavigationStack {
            SheetBody {
                    Text("The Health Index is a 1–100 score evaluating both the nutrient density of raw ingredients and the chemical transformations from cooking methods.")
                        .textStyle(.sansMd)
                        .fixedSize(horizontal: false, vertical: true)

                    tiers

                    SectionCard("Why cooking matters") {
                        paragraph("Identical ingredients yield drastically different nutritional profiles depending on preparation. Gentle methods (steaming, poaching, baking) preserve micronutrients and avoid oxidized fats, while deep-frying or high-heat charring significantly reduces the overall score.")
                    }

                    SectionCard("The science behind the score") {
                        paragraph("Calculations are grounded in validated nutritional profiling research, specifically the Tufts Food Compass and the Healthy Cooking Index. The index evaluates dishes across two pillars: ingredient nutrient density (favoring whole vegetables, fiber, and unsaturated fats over refined sugars and saturated fats) and thermal transformation (how heat and preparation alter micronutrient retention and fat oxidation).")
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                        Text("Nutritional guidance note")
                            .textStyle(.sansSm, tone: .tertiary, weight: .semibold)
                        Text("This index offers guidance on nutrient density and cooking quality. All meals have a place in a balanced, enjoyable diet.")
                            .textStyle(.sansSm, tone: .tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, DS.Spacing.sectionInset)
            }
            .screenTitle("Health methodology", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: [.fraction(0.88), .large])
    }

    private var tiers: some View {
        DSSection("Score tiers") {
            Card(layout: .list) {
                ForEach(HealthTier.allCases) { tier in
                    VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(tier.displayName)
                                .textStyle(.serifXs, tone: nil)
                                .foregroundStyle(tier.color)
                            Spacer(minLength: DS.Spacing.s2)
                            Text(tier.rangeDescription)
                                .textStyle(.sansSm, tone: .secondary, weight: .semibold, numeric: true)
                        }
                        Text(tier.explanation)
                            .textStyle(.sansSm, tone: .secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, DS.Spacing.s3)
                }
            }
        }
    }

    /// SectionCard README: "`sans-md` `text-secondary` for prose".
    private func paragraph(_ text: String) -> some View {
        Text(text)
            .textStyle(.sansMd, tone: .secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
