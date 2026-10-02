import SwiftUI

/// The store-backed PartyCard for Parties, Following and Discover. Members get `mine`
/// (the party's score, the invite / share context menu); everyone else gets
/// `discover` with the follow control under the card.
struct DinnerPartyCard: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var showingInviteSheet = false

    private var isMember: Bool { store.isMember(of: party.id) }
    private var meals: [Meal] { store.meals(forParty: party.id) }

    private var mealCountText: String {
        meals.count == 1 ? "1 meal" : "\(meals.count) meals"
    }

    private var recentMeals: [PartyCardMeal] {
        meals.map { PartyCardMeal(id: $0.id, source: .meal($0), title: store.dishName(forMeal: $0), date: $0.eatenOn) }
    }

    var body: some View {
        PartyCard(
            party: party,
            mode: isMember ? .mine : .discover,
            score: store.partyAverageScore(partyID: party.id)?.score,
            memberCount: store.members(of: party.id).count,
            meta: mealCountText,
            recentMeals: recentMeals
        ) {
            PartyDetailView(partyID: party.id)
        } join: {
            PartyFollowButton(party: party)
        }
        .contextMenu {
            if isMember {
                Button {
                    showingInviteSheet = true
                } label: {
                    Label("Invite Member", systemImage: "person.badge.plus")
                }

                ShareLink(
                    item: party.webInviteURL,
                    subject: Text("Join \(party.name) on Nom Nom"),
                    message: Text(party.shareMessage)
                ) {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            PartyInviteView(party: party)
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
