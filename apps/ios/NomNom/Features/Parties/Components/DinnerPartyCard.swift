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

    @State private var showingCreateMeal = false
    @State private var showingSettings = false
    @State private var confirmLeave = false

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
                Button {
                    showingCreateMeal = true
                } label: {
                    Label("Add meal", systemImage: "plus")
                }

                Button {
                    showingSettings = true
                } label: {
                    Label("Edit party", systemImage: "pencil")
                }

                ShareLink(
                    item: party.webInviteURL,
                    subject: Text("Join \(party.name) on Nom Nom"),
                    message: Text(party.shareMessage)
                ) {
                    Label("Share invite link", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    confirmLeave = true
                } label: {
                    Label("Leave party", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .sheet(isPresented: $showingCreateMeal) {
            MealEditorView(mealID: nil, prefilledPartyID: party.id)
        }
        .sheet(isPresented: $showingSettings) {
            PartySettingsSheet(party: party) {}
        }
        .alert(store.members(of: party.id).count <= 1 ? "Delete Dinner Party?" : "Leave Party?", isPresented: $confirmLeave) {
            Button("Cancel", role: .cancel) {}
            Button(store.members(of: party.id).count <= 1 ? "Delete Party" : "Leave Party", role: .destructive) {
                Task {
                    await store.leaveParty(party)
                }
            }
        } message: {
            if store.members(of: party.id).count <= 1 {
                Text("Since you are the last member, leaving will delete the dinner party.")
            } else {
                Text("You will lose access to meals served to this party.")
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
