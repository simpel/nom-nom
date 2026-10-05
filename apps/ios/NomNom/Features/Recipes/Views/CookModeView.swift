import SwiftUI

/// Cook mode ("Nom Nom iOS" canvas, CookMode): a full-screen walk through the recipe,
/// one step at a time. Close and the recipe name on top; "Step 3 of 5" with "About
/// 25 min left" over a Bar `sm`; the step (CookModeStepView); Back / Next at the
/// bottom, and on the last step "Log this meal" and "Back to step 4". The screen stays
/// awake while it is open.
struct CookModeView: View {
    let recipe: Recipe
    let onLogMeal: () -> Void

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var details: [RecipeStepDetail]?
    @State private var isLoadingDetails = true
    @State private var timer = CookModeTimer()

    private var steps: [String] { recipe.instructions }
    private var isLast: Bool { index == steps.count - 1 }

    private var timeLeft: String? {
        guard let details else { return nil }
        let minutes = details[index...].compactMap(\.minutes).reduce(0, +)
        return minutes > 0 ? "About \(minutes) min left" : "Last step"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    SectionHeader(title: "Step \(index + 1) of \(steps.count)", trailing: timeLeft)
                    Bar(value: Double(index + 1), max: Double(steps.count), size: .sm, label: "Step \(index + 1) of \(steps.count)")
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)

                ScrollView {
                    CookModeStepView(recipe: recipe, index: index, detail: details?[index], isLoadingDetail: isLoadingDetails, timer: timer)
                        .padding(.horizontal, DS.Spacing.gutter)
                        .padding(.vertical, DS.Spacing.s7)
                        .id(index)
                }

                CookModeFooter(
                    index: index,
                    isLast: isLast,
                    onBack: { move(-1) },
                    onNext: { move(1) },
                    onLogMeal: {
                        dismiss()
                        onLogMeal()
                    }
                )
            }
            .background(DS.Color.bg)
            .screenTitle(recipe.name, displayMode: .inline)
            .sheetCloseToolbar { dismiss() }
        }
        .task {
            details = await store.stepDetails(for: recipe)
            isLoadingDetails = false
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func move(_ delta: Int) {
        withAnimation(DS.Motion.state) {
            index = min(max(0, index + delta), steps.count - 1)
        }
    }
}
