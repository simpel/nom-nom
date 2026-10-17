import SwiftUI

/// One cook-mode step ("Nom Nom iOS" canvas, CookMode): the step in `serif-md`, the
/// "Start 20 min timer" button (secondary soft, clock) when the step waits on
/// something, and "For this step" — the ingredients it uses as ListRows `sm`, with the
/// group as meta in a grouped recipe ("Sauce"), so two "salt" rows can be told apart.
/// When the step adds something but we can't tell what ("Add the spices"), it lists
/// every ingredient under "Ingredients" instead (StepIngredientMatcher).
struct CookModeStepView: View {
    let recipe: Recipe
    @Environment(FoodStore.self) private var store
    let index: Int
    let detail: RecipeStepDetail?
    let timer: CookModeTimer

    /// Every ingredient and the name of the group it is in.
    private var allIngredients: [(item: RecipeIngredient, group: String?)] {
        let grouped = !recipe.ingredientGroups.isUngrouped
        return recipe.ingredientGroups.flatMap { group in
            group.ingredients.map { (item: $0, group: grouped ? group.title : nil) }
        }
    }

    /// The section title and the rows under this step, nil when it uses none.
    private var section: (title: String, rows: [(item: RecipeIngredient, group: String?)])? {
        let all = allIngredients
        let match = StepIngredientMatcher.ingredients(
            for: recipe.instructions[index],
            ingredients: all.map(\.item.trimmedIngredient),
            analyzed: detail?.ingredients
        )
        switch match {
        case .matched(let indexes): return ("For this step", indexes.map { all[$0] })
        case .all: return ("Ingredients", all)
        case .none: return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s7) {
            Text(recipe.instructions[index])
                .textStyle(.serifMd)
                .fixedSize(horizontal: false, vertical: true)

            if let minutes = detail?.minutes {
                timerButton(minutes: minutes)
            }

            if let section {
                DSSection(section.title) {
                    Card(layout: .list) {
                        ForEach(section.rows.indices, id: \.self) { i in
                            let (item, group) = section.rows[i]
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
