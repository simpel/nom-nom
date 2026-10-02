import SwiftUI

/// Average calories/protein/carbs/fat across a set of meals. Scope-agnostic — used for a
/// party's average dinner, a single person's average meal, or any other meal grouping.
/// A DSSection over ListRow key–value rows (ListRow README: "`title` + `value`, not
/// pressable, no chevron").
struct AverageMacrosCard: View {
    let macros: MacroNutrients

    var body: some View {
        DSSection("Average dinner") {
            Card(layout: .list) {
                ListRow("Calories", value: "\(macros.calories ?? 0) kcal")
                ListRow("Protein", value: grams(macros.proteinGrams))
                ListRow("Carbs", value: grams(macros.carbsGrams))
                ListRow("Fat", value: grams(macros.fatGrams))
            }
        }
    }

    private func grams(_ value: Double?) -> String {
        "\(Int(value ?? 0)) g"
    }
}
