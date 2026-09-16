import SwiftUI

/// Tab 1 — Meals. Shows a top action to log a meal, pending ratings, and your meal history.
struct MealsView: View {
    @Environment(FoodStore.self) private var store

    @State private var editorTarget: MealEditorTarget?

    @State private var mealToRemove: Meal?

    private var currentMeals: [Meal] {
        store.activeMeals
    }

    private var historySections: [(title: String, meals: [Meal])] {
        currentMeals.groupedByRelativeDate()
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
                        VStack(alignment: .leading, spacing: DS.Spacing.section) {
                            PageHeading(title: "Meals", actionTitle: "Add meal") {
                                editorTarget = .new
                            }

                            MealsToRateSection()

                            ForEach(historySections, id: \.title) { section in
                                SwipeableListCard(
                                    title: section.title,
                                    data: section.meals,
                                    dividerPadding: 74,
                                    leadingIcon: { _ in "trash.fill" },
                                    leadingColor: { _ in .red },
                                    onLeadingAction: { meal in
                                        mealToRemove = meal
                                    }
                                ) { meal in
                                    NavigationLink {
                                        MealDetailView(mealID: meal.id)
                                    } label: {
                                        MealRow(meal: meal, isMinimal: true)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
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
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                        .padding(.top, DS.Spacing.screenTop)
                        .padding(.bottom, DS.Spacing.screenBottom)
                    }
                    .background(DS.Color.bg)
                    .refreshable { await store.load() }
                }
            }
            .mainTabToolbar()
            .sheet(item: $editorTarget) { target in
                MealEditorView(mealID: target.mealID)
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

typealias LogListView = MealsView

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
