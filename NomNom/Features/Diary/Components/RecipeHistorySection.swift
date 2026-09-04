import SwiftUI

/// Section in RecipeDetailView showing cooked history filtered by dinner party, with auto-load pagination.
struct RecipeHistorySection: View {
    let history: [Meal]
    var selectedPartyID: UUID? = nil
    let onSelectMeal: (Meal) -> Void

    @Environment(FoodStore.self) private var store
    @State private var displayLimit: Int = 10

    private var filteredHistory: [Meal] {
        guard let selectedPartyID else { return history }
        return history.filter { store.parties(forMeal: $0.id).contains { $0.id == selectedPartyID } }
    }

    private var visibleMeals: [Meal] {
        Array(filteredHistory.prefix(displayLimit))
    }

    var body: some View {
        SectionCard("Cooked History", caption: "\(filteredHistory.count) occasions") {
            VStack(spacing: 8) {
                if filteredHistory.isEmpty {
                    Text(selectedPartyID == nil ? "No meals logged for this recipe yet." : "No meals logged for this dinner party.")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    ForEach(visibleMeals) { meal in
                        Button {
                            onSelectMeal(meal)
                        } label: {
                            RecipeHistoryRow(meal: meal)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if meal.id == visibleMeals.last?.id && displayLimit < filteredHistory.count {
                                displayLimit += 10
                            }
                        }

                        if meal.id != visibleMeals.last?.id {
                            Divider().overlay(DS.Color.line.opacity(0.25))
                        }
                    }
                }
            }
        }
    }
}
