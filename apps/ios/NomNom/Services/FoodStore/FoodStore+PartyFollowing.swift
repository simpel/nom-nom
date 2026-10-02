import Foundation
import Supabase

extension FoodStore {

    func toggleFollow(party: Party) async {
        guard canFollow(party) || isFollowing(partyID: party.id) else {
            // Cannot follow own or member party; if somehow following, clean up
            if isMember(of: party.id) && partyFollowers.contains(where: { $0.partyID == party.id && $0.userID == userID }) {
                await unfollowParty(party)
            }
            return
        }
        if isFollowing(partyID: party.id) {
            await unfollowParty(party)
        } else {
            await followParty(party)
        }
    }

    func followParty(_ party: Party) async {
        guard canFollow(party) else {
            Self.log.warning("Cannot follow party \(party.name) (\(party.id)): user is a member or party is not public.")
            return
        }
        guard !isFollowing(partyID: party.id) else { return }

        // 1. Optimistic local update so UI toggles immediately
        let optimisticFollower = PartyFollower(
            partyID: party.id,
            userID: userID
        )
        partyFollowers.append(optimisticFollower)
        reindex()

        // 2. Perform backend persistence
        do {
            struct RPCFollow: Encodable { let p_party_id: String }
            try await supabase.rpc("follow_party", params: RPCFollow(p_party_id: party.id.uuidString)).execute()
            errorMessage = nil
        } catch {
            do {
                let follower: PartyFollower = try await supabase
                    .from("party_followers")
                    .insert(NewPartyFollower(party_id: party.id, user_id: userID))
                    .select()
                    .single()
                    .execute()
                    .value

                if let idx = partyFollowers.firstIndex(where: { $0.id == optimisticFollower.id }) {
                    partyFollowers[idx] = follower
                }
                reindex()
                errorMessage = nil
            } catch {
                // If both fail, rollback optimistic state
                partyFollowers.removeAll { $0.id == optimisticFollower.id }
                reindex()
                errorMessage = Self.describe(error)
            }
        }
    }

    func unfollowParty(_ party: Party) async {
        let removed = partyFollowers.filter { $0.partyID == party.id && $0.userID == userID }
        guard !removed.isEmpty else { return }

        // 1. Optimistic local update so UI toggles immediately
        partyFollowers.removeAll { $0.partyID == party.id && $0.userID == userID }
        reindex()

        // 2. Perform backend persistence
        do {
            struct RPCUnfollow: Encodable { let p_party_id: String }
            try await supabase.rpc("unfollow_party", params: RPCUnfollow(p_party_id: party.id.uuidString)).execute()
            errorMessage = nil
        } catch {
            do {
                try await supabase
                    .from("party_followers")
                    .delete()
                    .eq("party_id", value: party.id.uuidString)
                    .eq("user_id", value: userID.uuidString)
                    .execute()

                errorMessage = nil
            } catch {
                // If both fail, rollback optimistic state
                partyFollowers.append(contentsOf: removed)
                reindex()
                errorMessage = Self.describe(error)
            }
        }
    }

    func updateParty(
        _ party: Party,
        name: String? = nil,
        about: String? = nil,
        isPublic: Bool? = nil,
        photos: PhotosDraft? = nil
    ) async {
        let trimmedName = name?.trimmedName
        let finalName = (trimmedName?.isEmpty == false) ? trimmedName : party.name
        let finalAbout = about?.trimmingCharacters(in: .whitespacesAndNewlines) ?? party.about
        let finalPublic = isPublic ?? party.isPublic

        var newPhotoPaths: [String]? = nil
        if let photos {
            do {
                let resolved = try await resolvePartyPhotos(photos, for: party)
                if resolved != party.photoPaths { newPhotoPaths = resolved }
            } catch {
                errorMessage = Self.describe(error)
                return
            }
        }
        let didChangePhoto = newPhotoPaths != nil

        guard finalName != party.name || finalAbout != party.about || finalPublic != party.isPublic || didChangePhoto else {
            return
        }

        do {
            let patch = PartyPatch(
                name: finalName,
                about: finalAbout,
                is_public: finalPublic,
                photo_paths: newPhotoPaths
            )

            let updated: Party = try await supabase
                .from("parties")
                .update(patch)
                .eq("id", value: party.id.uuidString)
                .select()
                .single()
                .execute()
                .value

            replaceLocal(party: updated)
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }
}
