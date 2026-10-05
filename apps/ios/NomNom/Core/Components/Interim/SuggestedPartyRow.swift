// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A ListRow for suggested parties with the reason it was suggested appended to the meta line.
///
/// ```swift
/// SuggestedPartyRow(party: party, reason: "Similar to The Friday Feast Club \u{00B7} Italian")
/// ```
struct SuggestedPartyRow: View {
    let party: Party
    var reason: String?

    @Environment(FoodStore.self) private var store

    private var metaLine: String {
        let count = store.members(of: party.id).count
        let members = count == 1 ? "1 member" : "\(count) members"
        return [members, reason].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " \u{00B7} ")
    }

    private var recentMeals: [PartyCardMeal] {
        store.meals(forParty: party.id)
            .sorted { $0.eatenOn > $1.eatenOn }
            .prefix(8)
            .map { PartyCardMeal(id: $0.id, source: .meal($0), title: store.dishName(forMeal: $0), date: $0.eatenOn) }
    }

    var body: some View {
        NavigationLink {
            PartyDetailView(partyID: party.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ListRow(
                    party.name,
                    meta: metaLine,
                    leading: .avatar(Avatar(party: party, size: .md, decorative: true)),
                    trailing: .view { PartyFollowButton(party: party) }
                )
                
                if !recentMeals.isEmpty {
                    Timeline(
                        occasions: recentMeals.map { TimelineOccasion(id: AnyHashable($0.id), date: $0.date, photo: $0.source) },
                        size: .mini,
                        bleed: CardSize.md.padding
                    )
                    .padding(.bottom, DS.Spacing.s3) 
                }
            }
        }
        .buttonStyle(ListRowButtonStyle())
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            Card(layout: .list) {
                SuggestedPartyRow(party: party, reason: "Similar to The Friday Feast Club \u{00B7} Italian")
            }
            .padding(DS.Spacing.gutter)
        }
    }
}
