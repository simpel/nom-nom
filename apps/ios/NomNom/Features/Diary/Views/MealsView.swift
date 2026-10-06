import SwiftUI

/// Tab 1 — Meals ("Nom Nom iOS" canvas): the MealsHeader, meals waiting for your
/// rating, then the history grouped This week / Last week / by month.
struct MealsView: View {
    @Environment(FoodStore.self) private var store

    @State private var editorTarget: MealEditorTarget?

    @State private var mealToRemove: Meal?
    @State private var mealToRemind: Meal?
    @State private var openMealID: UUID?

    private var currentMeals: [Meal] {
        store.activeMeals
    }

    private var historySections: [(title: String, meals: [Meal])] {
        currentMeals.groupedByWeek()
    }

    var body: some View {
        NavigationStack {
            Group {
                if currentMeals.isEmpty && store.awaitingMyRating.isEmpty {
                    MealsEmptyStateView {
                        editorTarget = .new
                    }
                    .refreshable { await store.load() }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Spacing.block) {
                            MealsHeader { editorTarget = .new }

                            MealsToRateSection()

                            ForEach(historySections, id: \.title) { section in
                                SwipeableListCard(
                                    title: section.title,
                                    caption: section.meals.count == 1 ? "1 meal" : "\(section.meals.count) meals",
                                    data: section.meals,
                                    leadingIcon: { meal in meal.createdBy == store.userID ? "trash.fill" : nil },
                                    leadingColor: { _ in DS.Color.destructive },
                                    onLeadingAction: { meal in
                                        mealToRemove = meal
                                    }
                                ) { meal in
                                    MealRow(
                                        meal: meal, metaStyle: .ratingProgress, isMinimal: true,
                                        action: { openMealID = meal.id },
                                        onRemind: { mealToRemind = meal }
                                    )
                                    .contextMenu {
                                        if meal.createdBy == store.userID {
                                            Button {
                                                editorTarget = .existing(meal.id)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                mealToRemove = meal
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.gutter)
                        .padding(.top, DS.Spacing.s5)
                        .padding(.bottom, DS.Spacing.s11)
                    }
                    .background(DS.Color.bg)
                    .refreshable { await store.load() }
                }
            }
            .mainTabToolbar()
            .sheet(item: $editorTarget) { target in
                MealEditorView(mealID: target.mealID)
            }
            .sheet(item: $mealToRemind) { meal in
                RemindRatersSheet(meal: meal)
            }
            .navigationDestination(item: $openMealID) { mealID in
                MealDetailView(mealID: mealID)
            }
            .alert(
                "Delete Meal?",
                isPresented: Binding(
                    get: { mealToRemove != nil },
                    set: { if !$0 { mealToRemove = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) {
                    mealToRemove = nil
                }
                if let meal = mealToRemove {
                    Button("Delete", role: .destructive) {
                        Task {
                            await store.delete(meal: meal)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this meal? This action cannot be undone.")
            }
        }
    }
}

#Preview("With Meals") {
    NomNomPreview(inNavigationStack: false) {
        MealsView()
    }
}

#Preview("Empty State") {
    NomNomPreview(store: .empty, inNavigationStack: false) {
        MealsView()
    }
}
