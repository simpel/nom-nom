import SwiftUI

/// When each dinner party the user belongs to last ate this recipe: one ListRow per
/// party (Avatar `sm`, name, "Last eaten …", the times served) that opens the party.
struct RecipePartyHistorySection: View {
    let recipeID: UUID

    @Environment(FoodStore.self) private var store

    @State private var selectedPartyForSheet: Party?

    private var history: [Meal] {
        store.servings(of: recipeID)
    }

    private var parties: [Party] {
        store.myParties
    }

    var body: some View {
        if !parties.isEmpty {
            DSSection("Dinner Parties History") {
                Card(layout: .list) {
                    ForEach(parties) { party in
                        row(for: party)
                    }
                }
            }
            .sheet(item: $selectedPartyForSheet) { party in
                NavigationStack {
                    PartyDetailView(partyID: party.id, showCloseButton: true)
                }
            }
        }
    }

    private func row(for party: Party) -> ListRow {
        let partyMealIDs = Set((store.mealPartiesByParty[party.id] ?? []).map(\.mealID))
        let partyServings = history.filter { partyMealIDs.contains($0.id) }
        return ListRow(
            party.name,
            meta: lastEatenText(partyServings.map(\.eatenOn).max()),
            value: partyServings.isEmpty ? nil : "\(partyServings.count)\u{00D7}",
            leading: .avatar(Avatar(party: party, size: .sm, decorative: true)),
            action: { selectedPartyForSheet = party }
        )
    }

    private func lastEatenText(_ lastEaten: Date?) -> String {
        guard let lastEaten else { return "Never eaten yet" }
        let days = Calendar.current.dateComponents([.day], from: lastEaten, to: .now).day ?? 0
        if days == 0 { return "Last eaten today" }
        if days == 1 { return "Last eaten yesterday" }
        if days < 30 { return "Last eaten \(days) days ago" }
        return "Last eaten on \(lastEaten.formatted(.dateTime.day().month(.abbreviated).year()))"
    }
}
