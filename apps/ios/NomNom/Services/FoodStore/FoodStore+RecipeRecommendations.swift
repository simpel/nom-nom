import Foundation
import Supabase

extension FoodStore {

    private struct RecommendRequest: Encodable {
        let party_id: String
        let force: Bool
    }

    private struct RecommendResponse: Decodable {
        let recommendations: [PartyRecommendation]
    }

    /// The party's AI picks that resolve to a recipe the store knows, in rank order.
    func pickedRecipes(forParty partyID: UUID) -> [(recipe: Recipe, reason: String)] {
        (partyRecommendations[partyID] ?? []).compactMap { pick in
            recipe(pick.dishID).map { ($0, pick.reason) }
        }
    }

    /// Asks `recommend-party-recipes` for the party's picks (the function serves its own
    /// 24h cache). Any failure leaves the previous picks alone; an empty answer clears them
    /// so the Recipes tab falls back to safe bets.
    func refreshRecommendations(forParty partyID: UUID, force: Bool = false) async {
        do {
            let response: RecommendResponse = try await supabase.functions.invoke(
                "recommend-party-recipes",
                options: FunctionInvokeOptions(body: RecommendRequest(party_id: partyID.uuidString, force: force))
            )
            partyRecommendations[partyID] = response.recommendations
        } catch {
            Self.log.error("recommend-party-recipes failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
