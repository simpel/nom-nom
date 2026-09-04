import SwiftUI

/// Tab 1 — Meals. Shows a top action to log a meal, pending ratings, and your meal history.
struct MealsView: View {
    @Environment(FoodStore.self) private var store

    @State private var editorTarget: MealEditorTarget?

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
                        LazyVStack(spacing: DS.Spacing.section) {
                            MealsToRateSection()

                            ForEach(historySections, id: \.title) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section.title.uppercased())
                                        .font(.caption.weight(.semibold))
                                        .tracking(0.5)
                                        .foregroundStyle(DS.Color.textSecondary)
                                        .padding(.horizontal, 4)

                                    VStack(spacing: 0) {
                                        ForEach(Array(section.meals.enumerated()), id: \.element.id) { index, meal in
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
                                                        Task { await store.delete(meal: meal) }
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }

                                            if index < section.meals.count - 1 {
                                                Divider()
                                                    .overlay(DS.Color.line.opacity(0.3))
                                                    .padding(.leading, 74)
                                            }
                                        }
                                    }
                                    .background(DS.Color.panel)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                            .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.screenHorizontal)
                        .padding(.top, DS.Spacing.screenTop)
                        .padding(.bottom, DS.Spacing.screenBottom)
                    }
                    .background(DS.Color.bg)
                    .refreshable { await store.load() }
                    .screenTitle(store.currentParty?.name ?? "Meals")
                }
            }
            .mainTabToolbar()
            .sheet(item: $editorTarget) { target in
                MealEditorView(mealID: target.mealID)
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
