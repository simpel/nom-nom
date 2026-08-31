import Foundation
import Supabase

extension FoodStore {

    @discardableResult
    func createParty(name: String) async -> Party? {
        let trimmed = name.trimmedName
        guard !trimmed.isEmpty else { return nil }
        do {
            let created: Party = try await supabase
                .from("parties")
                .insert(NewParty(name: trimmed, created_by: userID))
                .select()
                .single()
                .execute()
                .value

            parties.append(created)
            let refreshedMembers: [PartyMember] = try await supabase
                .from("party_members")
                .select()
                .eq("party_id", value: created.id.uuidString)
                .execute()
                .value
            partyMembers.append(contentsOf: refreshedMembers)
            reindex()
            currentParty = created
            errorMessage = nil
            return created
        } catch {
            errorMessage = Self.describe(error)
            return nil
        }
    }

    func updateParty(_ party: Party, name newName: String) async {
        let trimmed = newName.trimmedName
        guard !trimmed.isEmpty, trimmed != party.name else { return }
        do {
            let updated: Party = try await supabase
                .from("parties")
                .update(PartyNamePatch(name: trimmed))
                .eq("id", value: party.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            if let idx = parties.firstIndex(where: { $0.id == updated.id }) {
                parties[idx] = updated
            }
            if currentParty?.id == updated.id {
                currentParty = updated
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func leaveParty(_ party: Party) async {
        do {
            try await supabase
                .from("party_members")
                .delete()
                .eq("party_id", value: party.id.uuidString)
                .eq("user_id", value: userID.uuidString)
                .execute()

            partyMembers.removeAll { $0.partyID == party.id && $0.userID == userID }
            let isLast = !partyMembers.contains { $0.partyID == party.id }
            if isLast {
                parties.removeAll { $0.id == party.id }
            }
            if currentParty?.id == party.id {
                currentParty = nil
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func removeMember(user targetUserID: UUID, from party: Party) async {
        do {
            try await supabase
                .from("party_members")
                .delete()
                .eq("party_id", value: party.id.uuidString)
                .eq("user_id", value: targetUserID.uuidString)
                .execute()

            partyMembers.removeAll { $0.partyID == party.id && $0.userID == targetUserID }
            let isLast = !partyMembers.contains { $0.partyID == party.id }
            if isLast {
                parties.removeAll { $0.id == party.id }
                if currentParty?.id == party.id {
                    currentParty = nil
                }
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func inviteToParty(email rawEmail: String, party: Party) async -> Bool {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@") else {
            errorMessage = "That doesn't look like an email address."
            return false
        }
        if let myEmail = supabase.auth.currentUser?.email?.lowercased(), email == myEmail {
            errorMessage = "You cannot invite yourself."
            return false
        }
        do {
            let created: PartyInvite = try await supabase
                .from("party_invites")
                .insert(NewPartyInvite(party_id: party.id, inviter_id: userID, invitee_email: email))
                .select()
                .single()
                .execute()
                .value
            partyInvites.append(created)
            reindex()
            try? await loadProfiles()

            struct SendInvitePayload: Encodable {
                let party_id: String
                let invitee_email: String
            }
            let payload = SendInvitePayload(party_id: party.id.uuidString, invitee_email: email)
            do {
                try await supabase.functions.invoke(
                    "send-invite-email",
                    options: FunctionInvokeOptions(body: payload)
                )
                Self.log.info("Invite email sent successfully to \(email)")
            } catch {
                Self.log.error("send-invite-email function returned error: \(error.localizedDescription)")
            }

            errorMessage = nil
            return true
        } catch let error as PostgrestError where error.code == "23505" {
            errorMessage = "\(email) is already invited to this party."
            return false
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    func acceptPartyInvite(_ invite: PartyInvite) async {
        do {
            let member: PartyMember = try await supabase
                .from("party_members")
                .insert(NewPartyMember(party_id: invite.partyID, user_id: userID))
                .select()
                .single()
                .execute()
                .value

            _ = try await supabase
                .from("party_invites")
                .update(["status": InviteStatus.accepted.rawValue])
                .eq("id", value: invite.id.uuidString)
                .execute()

            partyMembers.append(member)
            if let idx = partyInvites.firstIndex(where: { $0.id == invite.id }) {
                partyInvites[idx].status = .accepted
            }
            if !parties.contains(where: { $0.id == invite.partyID }) {
                let fetched: Party = try await supabase
                    .from("parties")
                    .select()
                    .eq("id", value: invite.partyID.uuidString)
                    .single()
                    .execute()
                    .value
                parties.append(fetched)
            }
            reindex()
            errorMessage = nil
        } catch let error as PostgrestError where error.code == "23505" {
            if let idx = partyInvites.firstIndex(where: { $0.id == invite.id }) {
                partyInvites[idx].status = .accepted
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func declinePartyInvite(_ invite: PartyInvite) async {
        do {
            _ = try await supabase
                .from("party_invites")
                .update(["status": InviteStatus.declined.rawValue])
                .eq("id", value: invite.id.uuidString)
                .execute()
            if let idx = partyInvites.firstIndex(where: { $0.id == invite.id }) {
                partyInvites[idx].status = .declined
            }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func revokePartyInvite(_ invite: PartyInvite) async {
        do {
            try await supabase
                .from("party_invites")
                .delete()
                .eq("id", value: invite.id.uuidString)
                .execute()
            partyInvites.removeAll { $0.id == invite.id }
            reindex()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }
}
