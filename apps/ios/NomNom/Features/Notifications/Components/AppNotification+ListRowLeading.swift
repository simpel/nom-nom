import SwiftUI

extension AppNotification {
    /// The NotificationRow lead: the meal's photo (PhotoCard `xs`), the party's Avatar
    /// `sm`, the liked recipe's photo, else the kind's symbol as ListRow's icon lead.
    @MainActor
    func listRowLeading(in store: FoodStore) -> ListRowLeading {
        if let mealID, let meal = store.meal(mealID) {
            return .photo(.meal(meal))
        }
        if let party = matchedParty(in: store) {
            return .avatar(Avatar(party: party, size: .sm, decorative: true))
        }
        if let dishID, let recipe = store.dish(dishID) {
            return .photo(.recipe(recipe))
        }
        return .icon(symbol)
    }

    @MainActor
    private func matchedParty(in store: FoodStore) -> Party? {
        if let partyID, let party = store.parties.first(where: { $0.id == partyID }) {
            return party
        }
        // Fallback for rows written before party_id existed.
        guard kind == .partyInvite || kind == .partyJoined || kind == .partyFollowed else { return nil }
        return store.parties.first { body.contains($0.name) }
    }
}
