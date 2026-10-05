import SwiftUI

/// The store-backed PartyCard for Parties, Following and Discover. Members get `mine`
/// (the party's score, the invite / share context menu); everyone else gets
/// `discover` with the follow control under the card.
struct DinnerPartyCard: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var isMember: Bool { store.isMember(of: party.id) }
    private var meals: [Meal] { store.meals(forParty: party.id) }

    /// Newest first (PartyCard README: a Timeline `mini`).
    private var recentMeals: [PartyCardMeal] {
        meals.sorted { $0.eatenOn > $1.eatenOn }.prefix(8).map { PartyCardMeal(id: $0.id, source: .meal($0), title: store.dishName(forMeal: $0), date: $0.eatenOn) }
    }

    var body: some View {
        PartyCard(
            party: party,
            mode: isMember ? .mine : .discover,
            score: store.partyAverageScore(partyID: party.id)?.score,
            memberCount: isMember ? nil : store.members(of: party.id).count,
            recentMeals: recentMeals
        ) {
            PartyDetailView(partyID: party.id)
        } join: {
            PartyFollowButton(party: party)
        }
        .contextMenu {
            if isMember {
                ShareLink(
                    item: party.webInviteURL,
                    subject: Text("Join \(party.name) on Nom Nom"),
                    message: Text(party.shareMessage)
                ) {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                ForEach(store.parties.prefix(2)) { DinnerPartyCard(party: $0) }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}
