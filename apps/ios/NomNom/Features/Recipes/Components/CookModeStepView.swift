import SwiftUI

/// One cook-mode step ("Nom Nom iOS" canvas, CookMode): the step in `serif-md`, the
/// "Start 20 min timer" button (secondary soft, clock) when the step waits on
/// something, and "For this step" — the ingredients it uses as ListRows `sm`, with the
/// group as meta in a grouped recipe ("Sauce"), so two "salt" rows can be told apart.
struct CookModeStepView: View {
    let recipe: Recipe
    @Environment(FoodStore.self) private var store
    let index: Int
    let detail: RecipeStepDetail?
    let timer: CookModeTimer

    /// The step's ingredients and the name of the group each is in.
    private var stepIngredients: [(item: RecipeIngredient, group: String?)] {
        let grouped = !recipe.ingredientGroups.isUngrouped
        let all = recipe.ingredientGroups.flatMap { group in
            group.ingredients.map { (item: $0, group: grouped ? group.title : nil) }
        }
        return (detail?.ingredients ?? []).compactMap { all.indices.contains($0) ? all[$0] : nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s7) {
            Text(recipe.instructions[index])
                .textStyle(.serifMd)
                .fixedSize(horizontal: false, vertical: true)

            if let minutes = detail?.minutes {
                timerButton(minutes: minutes)
            }

            if !stepIngredients.isEmpty {
                DSSection("For this step") {
                    Card(layout: .list) {
                        ForEach(stepIngredients.indices, id: \.self) { i in
                            let (item, group) = stepIngredients[i]
                            ListRow(item.trimmedIngredient, meta: group, value: item.displayAmount(in: store.unitSystem), size: .sm)
                                .titleLines(nil)
                                .valueSemibold()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func timerButton(minutes: Int) -> some View {
        if timer.isRunning, timer.stepIndex == index {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                AppButton(
                    "\(timer.remainingText(at: context.date)) left \u{00B7} Stop",
                    icon: "clock", variant: .secondary, appearance: .soft
                ) {
                    timer.stop()
                }
            }
        } else {
            AppButton("Start \(minutes) min timer", icon: "clock", variant: .secondary, appearance: .soft) {
                timer.start(minutes: minutes, stepIndex: index, recipeName: recipe.name)
            }
        }
    }
}
