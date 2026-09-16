import Foundation
import Supabase

private struct SendEmailInvitePayload: Encodable {
    let party_id: String
    let invitee_email: String
}

private struct SendProfileInvitePayload: Encodable {
    let party_id: String
    let invitee_user_id: String
}

private struct ReactivatedInvitePatch: Encodable {
    let inviter_id: UUID
    let status: String
}

extension FoodStore {

    /// Finds profiles of people the user has interacted with who are not yet in the target party.
    func recentUninvitedProfiles(for partyID: UUID) -> [Profile] {
        let currentMemberIDs = Set(members(of: partyID).map(\.id))
        let pendingInviteeIDs = Set(invites(forParty: partyID).compactMap(\.inviteeID))

        var candidateProfiles: [Profile] = []
        for (id, profile) in profiles {
            if id == userID { continue }
            if currentMemberIDs.contains(id) { continue }
            if pendingInviteeIDs.contains(id) { continue }
            candidateProfiles.append(profile)
        }
        return candidateProfiles.sorted { $0.shownName.localizedCompare($1.shownName) == .orderedAscending }
    }

    /// Invites a user to a dinner party by email address.
    @discardableResult
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
                .insert(NewPartyInvite(party_id: party.id, inviter_id: userID, invitee_id: nil, invitee_email: email))
                .select()
                .single()
                .execute()
                .value
            partyInvites.append(created)
            reindex()
            try? await loadProfiles()

            let payload = SendEmailInvitePayload(party_id: party.id.uuidString, invitee_email: email)
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
            if await reactivateInvite(partyID: party.id, inviteeID: nil, inviteeEmail: email) {
                try? await loadProfiles()
                let payload = SendEmailInvitePayload(party_id: party.id.uuidString, invitee_email: email)
                try? await supabase.functions.invoke("send-invite-email", options: FunctionInvokeOptions(body: payload))
                errorMessage = nil
                return true
            }
            errorMessage = "\(email) is already invited to this party."
            return false
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    /// Invites an existing profile to a party by user ID.
    @discardableResult
    func inviteToParty(profile: Profile, party: Party) async -> Bool {
        do {
            let created: PartyInvite = try await supabase
                .from("party_invites")
                .insert(NewPartyInvite(party_id: party.id, inviter_id: userID, invitee_id: profile.id, invitee_email: nil))
                .select()
                .single()
                .execute()
                .value
            partyInvites.append(created)
            reindex()

            let payload = SendProfileInvitePayload(party_id: party.id.uuidString, invitee_user_id: profile.id.uuidString)
            do {
                try await supabase.functions.invoke(
                    "send-invite-email",
                    options: FunctionInvokeOptions(body: payload)
                )
                Self.log.info("Invite sent successfully to profile \(profile.shownName)")
            } catch {
                Self.log.error("send-invite-email function error: \(error.localizedDescription)")
            }

            errorMessage = nil
            return true
        } catch let error as PostgrestError where error.code == "23505" {
            if await reactivateInvite(partyID: party.id, inviteeID: profile.id, inviteeEmail: nil) {
                let payload = SendProfileInvitePayload(party_id: party.id.uuidString, invitee_user_id: profile.id.uuidString)
                try? await supabase.functions.invoke("send-invite-email", options: FunctionInvokeOptions(body: payload))
                errorMessage = nil
                return true
            }
            errorMessage = "\(profile.shownName) is already invited to this party."
            return false
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    /// A previous invite for this person on this party already exists (they
    /// declined, or accepted and later left/was removed). The unique
    /// (party_id, invitee) index means we can't insert a fresh row, so flip
    /// the stale one back to pending instead of leaving the host stuck with
    /// a silent "already invited" dead end.
    private func reactivateInvite(partyID: UUID, inviteeID: UUID?, inviteeEmail: String?) async -> Bool {
        do {
            let existing: PartyInvite
            if let inviteeID {
                existing = try await supabase.from("party_invites").select()
                    .eq("party_id", value: partyID.uuidString)
                    .eq("invitee_id", value: inviteeID.uuidString)
                    .single().execute().value
            } else if let inviteeEmail {
                existing = try await supabase.from("party_invites").select()
                    .eq("party_id", value: partyID.uuidString)
                    .eq("invitee_email", value: inviteeEmail)
                    .single().execute().value
            } else {
                return false
            }
            guard existing.status != .pending else { return false }

            let updated: PartyInvite = try await supabase
                .from("party_invites")
                .update(ReactivatedInvitePatch(inviter_id: userID, status: InviteStatus.pending.rawValue))
                .eq("id", value: existing.id.uuidString)
                .select()
                .single()
                .execute()
                .value

            if let idx = partyInvites.firstIndex(where: { $0.id == updated.id }) {
                partyInvites[idx] = updated
            } else {
                partyInvites.append(updated)
            }
            reindex()
            return true
        } catch {
            Self.log.error("Failed to reactivate party invite: \(error.localizedDescription)")
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
            if partyFollowers.contains(where: { $0.partyID == invite.partyID && $0.userID == userID }) {
                partyFollowers.removeAll { $0.partyID == invite.partyID && $0.userID == userID }
                _ = try? await supabase
                    .from("party_followers")
                    .delete()
                    .eq("party_id", value: invite.partyID.uuidString)
                    .eq("user_id", value: userID.uuidString)
                    .execute()
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

    @discardableResult
    func resendPartyInvite(_ invite: PartyInvite) async -> Bool {
        guard let email = invite.inviteeEmail else { return false }
        struct SendInvitePayload: Encodable {
            let party_id: String
            let invitee_email: String
        }
        let payload = SendInvitePayload(party_id: invite.partyID.uuidString, invitee_email: email)
        do {
            try await supabase.functions.invoke(
                "send-invite-email",
                options: FunctionInvokeOptions(body: payload)
            )
            Self.log.info("Invite email resent successfully to \(email)")
            errorMessage = nil
            return true
        } catch {
            Self.log.error("send-invite-email function returned error: \(error.localizedDescription)")
            errorMessage = Self.describe(error)
            return false
        }
    }
}
