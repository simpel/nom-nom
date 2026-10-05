import Foundation
import Supabase

extension FoodStore {

    static let partySuggestionPageSize = 10

    /// Loads the first page (`reset`) or the next one. One request at a time; a short page
    /// ends the list.
    func loadPartySuggestions(reset: Bool = false) async {
        guard !isLoadingPartySuggestions, reset || partySuggestionsHasMore else { return }
        isLoadingPartySuggestions = true
        defer { isLoadingPartySuggestions = false }

        struct Params: Encodable { let p_limit: Int; let p_offset: Int }
        // The server leaves out parties you have since followed or joined, so drop them here
        // too; otherwise the offset would skip one row per follow.
        partySuggestions.removeAll { suggestion in
            isMember(of: suggestion.partyID) || followedPartyIDs.contains(suggestion.partyID)
        }
        let offset = reset ? 0 : partySuggestions.count
        do {
            let page: [PartySuggestion] = try await supabase
                .rpc("suggest_parties", params: Params(p_limit: Self.partySuggestionPageSize, p_offset: offset))
                .execute()
                .value
            if reset { partySuggestions = [] }
            let known = Set(partySuggestions.map(\.partyID))
            partySuggestions.append(contentsOf: page.filter { !known.contains($0.partyID) })
            partySuggestionsHasMore = page.count == Self.partySuggestionPageSize
        } catch {
            // Suggestions are a nicety: stop paging rather than surface an error banner.
            Self.log.error("suggest_parties failed: \(error.localizedDescription, privacy: .public)")
            partySuggestionsHasMore = false
        }
    }

    /// "Similar to The Friday Feast Club · Italian", or nil when the party could not be scored.
    func suggestionReason(for suggestion: PartySuggestion) -> String? {
        guard let similarID = suggestion.similarPartyID, let similar = party(similarID) else { return nil }
        guard let cuisine = suggestion.sharedCuisine, !cuisine.isEmpty else { return "Similar to \(similar.name)" }
        return "Similar to \(similar.name) \u{00B7} \(cuisine.capitalized)"
    }
}
