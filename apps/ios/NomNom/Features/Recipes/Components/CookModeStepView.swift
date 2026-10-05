import SwiftUI

/// One cook-mode step ("Nom Nom iOS" canvas, CookMode): the step in `serif-md`, the
/// "Start 20 min timer" button (secondary soft, clock) when the step waits on
/// something, and "For this step" — the ingredients it uses as ListRows `sm`.
struct CookModeStepView: View {
    let recipe: Recipe
    @Environment(FoodStore.self) private var store
    let index: Int
    let detail: RecipeStepDetail?
    /// The step's timer and ingredients are still on their way (`analyze-recipe-steps`).
    var isLoadingDetail: Bool = false
    let timer: CookModeTimer

    private var stepIngredients: [RecipeIngredient] {
        (detail?.ingredients ?? []).compactMap { recipe.ingredients.indices.contains($0) ? recipe.ingredients[$0] : nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s7) {
            Text(recipe.instructions[index])
                .textStyle(.serifMd)
                .fixedSize(horizontal: false, vertical: true)

            if let minutes = detail?.minutes {
                timerButton(minutes: minutes)
            }

            if isLoadingDetail {
                DSSection("For this step") {
                    Skeleton(rows: 2, trailing: true, meta: false, label: "Loading this step")
                }
            } else if !stepIngredients.isEmpty {
                DSSection("For this step") {
                    Card(layout: .list) {
                        ForEach(stepIngredients) { item in
                            ListRow(item.trimmedIngredient, value: item.displayAmount(in: store.unitSystem), size: .sm)
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
