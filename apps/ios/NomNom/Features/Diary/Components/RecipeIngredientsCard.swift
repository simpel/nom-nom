import SwiftUI

/// A recipe's ingredients ("Nom Nom iOS" canvas): a Section "Ingredients" with the
/// count, over a list Card. When the recipe says how many it serves, the first row is
/// "Servings" with a ValueStepper `sm`, and every amount scales with it
/// (QuantityScaler; free-text amounts stay as written). Each ingredient is a ListRow
/// `sm`: the name (it wraps) and the amount, semibold, as its tabular value. The
/// "Imperial units" toggle is the person's `UnitSystem` (saved on their profile); amounts go through
/// MeasurementConverter.
struct RecipeIngredientsCard: View {
    let ingredients: [RecipeIngredient]
    /// The recipe's own servings; nil hides the stepper and shows amounts as written.
    var serves: Int?

    @State private var servings: Int
    @Environment(FoodStore.self) private var store

    init(ingredients: [RecipeIngredient], serves: Int? = nil) {
        self.ingredients = ingredients
        self.serves = serves
        self._servings = State(initialValue: serves ?? 1)
    }

    private var validIngredients: [RecipeIngredient] {
        ingredients.filter { !$0.isEmpty }
    }

    private var factor: Double {
        guard let serves, serves > 0 else { return 1 }
        return Double(servings) / Double(serves)
    }

    var body: some View {
        if !validIngredients.isEmpty {
            DSSection("Ingredients", trailing: "\(validIngredients.count)") {
                Card(layout: .list) {
                    ListRow("Imperial units", trailing: .toggle(Binding(get: { store.unitSystem.isImperial }, set: { on in Task { await store.setUnitSystem(on ? .imperial : .metric) } })))
                    if serves != nil {
                        ListRow(
                            "Servings",
                            trailing: .view {
                                ValueStepper(value: $servings, in: 1...24, size: .sm, label: "Servings")
                            }
                        )
                    }
                    ForEach(validIngredients) { item in
                        ListRow(item.trimmedIngredient, value: item.displayAmount(scaledBy: factor, in: store.unitSystem), size: .sm)
                            .titleLines(nil)
                            .valueSemibold()
                    }
                }
            }
        }
    }
}
