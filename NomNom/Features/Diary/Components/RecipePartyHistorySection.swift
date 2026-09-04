import SwiftUI

/// Section displaying when each dinner party the user belongs to last ate this recipe.
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
            SectionCard("Dinner Parties History") {
                VStack(spacing: 10) {
                    ForEach(parties) { party in
                        Button {
                            selectedPartyForSheet = party
                        } label: {
                            partyRow(for: party)
                        }
                        .buttonStyle(.plain)

                        if party.id != parties.last?.id {
                            Divider()
                        }
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

    private func partyRow(for party: Party) -> some View {
        let partyMealIDs = Set((store.mealPartiesByParty[party.id] ?? []).map(\.mealID))
        let partyServings = history.filter { partyMealIDs.contains($0.id) }
        let lastEaten = partyServings.map(\.eatenOn).max()

        return HStack(spacing: 12) {
            PartyAvatar(party: party, size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(party.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let lastEaten {
                    let days = Calendar.current.dateComponents([.day], from: lastEaten, to: .now).day ?? 0
                    let relativeText: String = {
                        if days == 0 { return "Last eaten today" }
                        if days == 1 { return "Last eaten yesterday" }
                        if days < 30 { return "Last eaten \(days) days ago" }
                        return "Last eaten on \(lastEaten.formatted(.dateTime.day().month(.abbreviated).year()))"
                    }()

                    Text(relativeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Never eaten yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if partyServings.count > 0 {
                Text("\(partyServings.count)×")
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
