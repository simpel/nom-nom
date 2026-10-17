import SwiftUI

/// A recipe's ingredients ("Nom Nom iOS" canvas): a Section "Ingredients" over a list
/// Card. When the recipe says how many it serves, a "Servings" row with a ValueStepper
/// `sm` scales every amount (QuantityScaler; free-text amounts stay as written). Each
/// ingredient is a ListRow `sm`: the name (it wraps) and the amount, semibold, as its
/// tabular value. The "Imperial units" toggle is the person's `UnitSystem` (saved on
/// their profile); amounts go through MeasurementConverter. "Keep screen on" is the
/// device's KeepScreenOn setting, the same toggle cook mode shows.
///
/// Grouped recipes ("Sauce", "Salad") keep the settings rows and the first group when
/// it has no name in the "Ingredients" card, then give every named group its own
/// Section titled by its name, `DS.Spacing.block` apart.
struct RecipeIngredientsCard: View {
    let groups: [IngredientGroup]
    /// The recipe's own servings; nil hides the stepper and shows amounts as written.
    var serves: Int?

    @State private var servings: Int
    @AppStorage(KeepScreenOn.storageKey) private var keepScreenOn = true
    @Environment(FoodStore.self) private var store

    init(groups: [IngredientGroup], serves: Int? = nil) {
        self.groups = groups.cleaned
        self.serves = serves
        self._servings = State(initialValue: serves ?? 1)
    }

    private var factor: Double {
        guard let serves, serves > 0 else { return 1 }
        return Double(servings) / Double(serves)
    }

    /// The leading unnamed group, shown in the "Ingredients" card under the settings.
    private var leadGroup: IngredientGroup? {
        groups.first.flatMap { $0.title == nil ? $0 : nil }
    }

    private var titledGroups: ArraySlice<IngredientGroup> {
        leadGroup == nil ? groups[...] : groups.dropFirst()
    }

    var body: some View {
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                DSSection("Ingredients") {
                    Card(layout: .list) {
                        ListRow("Imperial units", trailing: .toggle(Binding(get: { store.unitSystem.isImperial }, set: { on in Task { await store.setUnitSystem(on ? .imperial : .metric) } })))
                        ListRow("Keep screen on", meta: "The screen won't dim while you cook", trailing: .toggle($keepScreenOn))
                        if serves != nil {
                            ListRow(
                                "Servings",
                                trailing: .view {
                                    ValueStepper(value: $servings, in: 1...24, size: .sm, label: "Servings")
                                }
                            )
                        }
                        if let leadGroup { rows(leadGroup.ingredients) }
                    }
                }

                ForEach(titledGroups) { group in
                    // A later group without a name still gets a header, so it never
                    // reads as part of the group above it.
                    DSSection(group.title ?? "More") {
                        Card(layout: .list) { rows(group.ingredients) }
                    }
                }
            }
        }
    }

    private func rows(_ ingredients: [RecipeIngredient]) -> some View {
        ForEach(ingredients) { item in
            ListRow(item.trimmedIngredient, value: item.displayAmount(scaledBy: factor, in: store.unitSystem), size: .sm)
                .titleLines(nil)
                .valueSemibold()
        }
    }
}
