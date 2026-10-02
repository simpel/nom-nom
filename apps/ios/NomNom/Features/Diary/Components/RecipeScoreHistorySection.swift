import SwiftUI

/// A recipe's average score per occasion over time, one TrendChart series per dinner
/// party (or a single "Household" line when it was never served to a party). The
/// section's context menu filters to one party.
///
/// No caller yet: RecipeDetailView shows the recipe's history as a Timeline.
struct RecipeScoreHistorySection: View {
    let recipe: Recipe
    let history: [Meal]
    @Binding var selectedPartyID: UUID?
    let onSelectMeal: (Meal) -> Void

    @Environment(FoodStore.self) private var store

    private static let visibleDays = 30

    private var availableParties: [Party] {
        let partyIDs = Set(history.flatMap { store.parties(forMeal: $0.id).map(\.id) })
        return store.myParties.filter { partyIDs.contains($0.id) }
    }

    /// Party name → the dated average scores (0–1) of its rated servings.
    private var pointsByParty: [(name: String, points: [TrendPoint])] {
        var grouped: [String: [TrendPoint]] = [:]
        var order: [String] = []
        for meal in history.sorted(by: { $0.eatenOn < $1.eatenOn }) {
            guard let score = store.averageScore(forMeal: meal.id) else { continue }
            let point = TrendPoint(date: meal.eatenOn, value: score)
            let parties = store.parties(forMeal: meal.id)
            let names: [String]
            if let selectedPartyID {
                guard parties.contains(where: { $0.id == selectedPartyID }) else { continue }
                names = [store.party(selectedPartyID)?.name ?? "Dinner Party"]
            } else {
                names = parties.isEmpty ? ["Household"] : parties.map(\.name)
            }
            for name in names {
                if grouped[name] == nil { order.append(name) }
                grouped[name, default: []].append(point)
            }
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    private var series: [TrendSeries] {
        pointsByParty.enumerated().map { index, entry in
            TrendSeries(id: AnyHashable(entry.name), name: entry.name, colorIndex: index, points: entry.points)
        }
    }

    var body: some View {
        DSSection(headerTitle) {
            TrendChart(series: series, visibleDays: Self.visibleDays, emptyMessage: "No score history yet")
                .contentShape(Rectangle())
                .contextMenu { dinnerPartyMenuContent }
        }
    }

    private var headerTitle: String {
        if let selectedPartyID, let party = store.party(selectedPartyID) {
            return "Score History — \(party.name)"
        }
        return "Score History"
    }

    @ViewBuilder
    private var dinnerPartyMenuContent: some View {
        Section("Filter by Dinner Party") {
            Button { selectedPartyID = nil } label: {
                Label("All Dinner Parties", systemImage: selectedPartyID == nil ? "checkmark" : "")
            }
            ForEach(availableParties) { party in
                Button { selectedPartyID = party.id } label: {
                    Label(party.name, systemImage: selectedPartyID == party.id ? "checkmark" : "")
                }
            }
        }
    }
}
