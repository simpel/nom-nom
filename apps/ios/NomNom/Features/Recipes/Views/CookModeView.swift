import SwiftUI

/// Cook mode ("Nom Nom iOS" canvas, CookMode): a full-screen walk through the recipe,
/// one step at a time. Close and the recipe name on top; "Step 3 of 5" with "About
/// 25 min left" over a Bar `sm`; the step (CookModeStepView); Back / Next at the
/// bottom, and on the last step "Create a meal". Pinned to the bottom on every step,
/// the "Keep screen on" toggle (KeepScreenOn), so the screen never dims mid-recipe.
struct CookModeView: View {
    let recipe: Recipe
    let onLogMeal: () -> Void

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var timer = CookModeTimer()
    @AppStorage(KeepScreenOn.storageKey) private var keepScreenOn = true

    private var steps: [String] { recipe.instructions }
    private var isLast: Bool { index == steps.count - 1 }
    private var details: [RecipeStepDetail]? { recipe.currentStepDetails }

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

                TabView(selection: $index) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        ScrollView {
                            CookModeStepView(recipe: recipe, index: i, detail: details?[i], timer: timer)
                                .padding(.horizontal, DS.Spacing.gutter)
                                .padding(.vertical, DS.Spacing.s7)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .background(DS.Color.bg)
            .screenTitle(recipe.name, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").fontWeight(.semibold)
                    }
                    .accessibilityLabel("Close")
                    .barItemStyle()
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: DS.Spacing.s4) {
                        Button(action: { move(-1) }) {
                            Image(systemName: "chevron.left").fontWeight(.semibold)
                        }
                        .disabled(index == 0)
                        .accessibilityLabel("Previous step")
                        .barItemStyle()

                        Button(action: { move(1) }) {
                            Image(systemName: "chevron.right").fontWeight(.semibold)
                        }
                        .disabled(isLast)
                        .accessibilityLabel("Next step")
                        .barItemStyle()
                    }
                }
            }
        }
        .keepsScreenOn()
    }

    /// "Create a meal" on the last step, over the "Keep screen on" toggle on every step.
    private var bottomBar: some View {
        VStack(spacing: DS.Spacing.s4) {
            if isLast {
                AppButton("Create a meal", size: .lg, fullWidth: true) {
                    dismiss()
                    onLogMeal()
                }
            }
            Card(layout: .list) {
                ListRow("Keep screen on", meta: "The screen won't dim while you cook", trailing: .toggle($keepScreenOn))
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.vertical, DS.Spacing.s4)
        .background(.regularMaterial)
    }

    private func move(_ delta: Int) {
        withAnimation(DS.Motion.state) {
            index = min(max(0, index + delta), steps.count - 1)
        }
    }
}
