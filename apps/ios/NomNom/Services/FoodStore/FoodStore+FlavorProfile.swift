import Foundation
import Supabase

/// Fetches the same server-aggregated ingredient taste profile the web admin dashboards
/// render (`get_flavor_profile`), so this app doesn't recompute loved/polarizing/disliked
/// stats itself from raw ingredient text.
extension FoodStore {

    /// Aggregate ingredient taste profile for a party's shared meal history.
    func fetchFlavorProfile(forParty partyID: UUID) async throws -> [FlavorProfileEntry] {
        try await fetchFlavorProfile(scope: "party", id: partyID)
    }

    /// Aggregate ingredient taste profile for one rater's own meal history.
    func fetchFlavorProfile(for rater: RaterRef) async throws -> [FlavorProfileEntry] {
        try await fetchFlavorProfile(scope: "person", id: rater.id)
    }

    private func fetchFlavorProfile(scope: String, id: UUID) async throws -> [FlavorProfileEntry] {
        struct Params: Encodable {
            let p_scope: String
            let p_id: UUID
        }
        do {
            return try await supabase
                .rpc("get_flavor_profile", params: Params(p_scope: scope, p_id: id))
                .execute()
                .value
        } catch {
            Self.log.error("Failed to fetch flavor profile (scope: \(scope, privacy: .public)): \(error.localizedDescription)")
            throw error
        }
    }
}
