import SwiftUI

/// Average calories/protein/carbs/fat across a set of meals. Scope-agnostic — used for a
/// party's average dinner, a single person's average meal, or any other meal grouping.
struct AverageMacrosCard: View {
    let macros: MacroNutrients

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Average Dinner")
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Calories")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(macros.calories ?? 0)")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Protein")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(Int(macros.proteinGrams ?? 0))g")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Carbs")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(Int(macros.carbsGrams ?? 0))g")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Fat")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text("\(Int(macros.fatGrams ?? 0))g")
                        .font(.headline)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.Color.sunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
    }
}
