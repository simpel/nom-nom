import SwiftUI

/// Shows each member's individual average score for the party.
struct PartyMemberScoresSheet: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var members: [Profile] {
        store.members(of: party.id)
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                Card(layout: .list) {
                    ForEach(members) { member in
                        let stats = store.partyAverageScore(partyID: party.id, for: member.raterRef, limit: .max)
                        
                        ListRow(
                            member.shownName,
                            meta: countText(for: stats),
                            leading: .avatar(Avatar(profile: member, size: .sm, decorative: true)),
                            trailing: trailingSlot(for: stats)
                        )
                    }
                }
            }
            .screenTitle("Average ratings", displayMode: .inline)
            .sheetCloseToolbar()
        }
        .dsSheet()
    }

    private func countText(for stats: FoodStore.PartyScoreStats?) -> String {
        guard let stats = stats else { return "No ratings yet" }
        return stats.count == 1 ? "1 rating" : "\(stats.count) ratings"
    }

    private func trailingSlot(for stats: FoodStore.PartyScoreStats?) -> ListRowTrailing? {
        if let stats = stats {
            return .view {
                ScoreValue(score: stats.score, verdict: stats.reaction.shortLabel, size: .sm)
            }
        }
        return nil
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyMemberScoresSheet(party: party)
        }
    }
}
