import Foundation
import Supabase

/// Why an invite code didn't resolve to a party.
enum PartyInviteRequestError: LocalizedError {
    case notFound
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "No dinner party uses that code. Check it and try again."
        case .failed(let message): return message
        }
    }
}

extension FoodStore {

    private struct RequestInviteParams: Encodable {
        var p_party_id: String?
        var p_code: String?
    }

    /// Files a pending invite for the viewer from a party's invite link, so it lands in
    /// the inbox to accept or decline. Returns the party id; a member gets it back as is.
    @discardableResult
    func requestPartyInvite(partyID: UUID) async -> UUID? {
        do {
            return try await requestInvite(RequestInviteParams(p_party_id: partyID.uuidString))
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// The same from a typed or pasted invite code (onboarding's "I have an invite").
    /// A pasted invite link works too: its party id is read out of it.
    func requestPartyInvite(code raw: String) async throws -> UUID {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), case .partyInvite(let id) = DeepLink(url: url) {
            return try await requestInvite(RequestInviteParams(p_party_id: id.uuidString))
        }
        return try await requestInvite(RequestInviteParams(p_code: trimmed))
    }

    private func requestInvite(_ params: RequestInviteParams) async throws -> UUID {
        let partyID: UUID
        do {
            partyID = try await supabase
                .rpc("request_party_invite", params: params)
                .execute()
                .value
        } catch let error as PostgrestError where error.code == "P0002" {
            throw PartyInviteRequestError.notFound
        } catch {
            throw PartyInviteRequestError.failed(Self.describe(error))
        }
        await refreshPartyInvites()
        return partyID
    }

    /// Re-reads what an invite touches: the party, the invite row and its notification.
    private func refreshPartyInvites() async {
        do {
            async let parties: [Party] = supabase.from("parties").select().execute().value
            async let invites: [PartyInvite] = supabase.from("party_invites").select().execute().value
            async let inbox: [AppNotification] = supabase.from("notifications").select().execute().value
            self.parties = try await parties
            self.partyInvites = try await invites
            self.notifications = try await inbox
            reindex()
            try await loadProfiles()
        } catch {
            Self.log.error("refreshPartyInvites failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// The viewer's pending invite to a party, if any.
    func pendingInvite(toParty partyID: UUID) -> PartyInvite? {
        pendingPartyInvites.first { $0.partyID == partyID }
    }
}
