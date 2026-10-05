import SwiftUI

/// The detail behind `RecipePartyInsightsCard` ("Nom Nom iOS" BottomSheet): SheetHero
/// with the party's score for the recipe in `pro`, then who gave what as a SegmentedBar
/// key: one block per person, adding up to the score, and every time the party cooked it.
struct RecipePartyInsightsSheet: View {
    let recipe: Recipe
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var selectedMeal: Meal?

    private var meals: [Meal] { store.partyServings(of: recipe.id, partyID: party.id) }
    private var history: [Meal] { meals.sorted { $0.eatenOn > $1.eatenOn } }
    private var shares: [RaterRef: Double] { store.scoreShares(forDish: recipe.id, inParty: party.id) }

    private var segments: [SegmentedBarSegment] {
        store.barSegments(shares).map { SegmentedBarSegment(label: $0.label ?? "", value: $0.value, ink: $0.ink) }
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                SheetHero(
                    score: store.averageScore(across: meals),
                    lead: "\(party.name) has eaten this \(meals.count == 1 ? "once" : "\(meals.count) times").",
                    ink: .pro
                )
                if !segments.isEmpty {
                    SegmentedBar(segments, legend: .rows, title: "Who scored it", trailing: "Adds up to the score")
                }
                if !history.isEmpty {
                    RecipeHistorySection(history: history) { selectedMeal = $0 }
                }
            }
            .sheet(item: $selectedMeal) { meal in
                NavigationStack { MealDetailView(mealID: meal.id, showCloseButton: true) }
            }
            .screenTitle("\(party.name) insights", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet(detents: [.fraction(0.85), .large])
    }
}
