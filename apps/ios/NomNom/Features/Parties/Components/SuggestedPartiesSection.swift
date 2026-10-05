import SwiftUI

/// Public parties that resemble the viewer's own, best match first, paged: a `card`
/// Skeleton under the last party loads the next page when it scrolls into view. Hidden
/// while there is nothing to suggest.
struct SuggestedPartiesSection: View {
    @Environment(FoodStore.self) private var store

    /// Parties joined or followed since the page was fetched drop out; so do ones the
    /// store has not loaded.
    private var visible: [(party: Party, reason: String?)] {
        store.partySuggestions.compactMap { suggestion in
            guard let party = store.party(suggestion.partyID),
                  store.canFollow(party), !store.isFollowing(partyID: party.id)
            else { return nil }
            return (party, store.suggestionReason(for: suggestion))
        }
    }

    var body: some View {
        if !visible.isEmpty || store.partySuggestionsHasMore {
            DSSection("Suggested parties") {
                LazyVStack(spacing: DS.Spacing.s4) {
                    ForEach(visible, id: \.party.id) { SuggestedPartyCard(party: $0.party, reason: $0.reason) }
                    if store.partySuggestionsHasMore {
                        Skeleton(layout: .card, lines: 2)
                            .task(id: store.partySuggestions.count) { await store.loadPartySuggestions() }
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        SuggestedPartiesSection()
            .padding(DS.Spacing.gutter)
    }
}
