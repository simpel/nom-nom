import Foundation
import Supabase

extension FoodStore {

    func toggleFollow(party: Party) async {
        if isFollowing(partyID: party.id) {
            await unfollowParty(party)
        } else {
            await followParty(party)
        }
    }

    func followParty(_ party: Party) async {
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
        guard isFollowing(partyID: party.id) else { return }

        // 1. Optimistic local update so UI toggles immediately
        let removed = partyFollowers.filter { $0.partyID == party.id && $0.userID == userID }
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
        newPhotoData: Data? = nil,
        removePhoto: Bool = false
    ) async {
        let trimmedName = name?.trimmedName
        let finalName = (trimmedName?.isEmpty == false) ? trimmedName : party.name
        let finalAbout = about?.trimmingCharacters(in: .whitespacesAndNewlines) ?? party.about
        let finalPublic = isPublic ?? party.isPublic

        var newPhotoPath = party.photoPath
        var didChangePhoto = false

        if removePhoto {
            if let oldPath = party.photoPath {
                _ = try? await supabase.storage.from(SupabaseConfig.partyBucket).remove(paths: [oldPath])
                PhotoCache.shared.forget(oldPath)
            }
            newPhotoPath = nil
            didChangePhoto = true
        } else if let newPhotoData, let prepared = PhotoTools.prepare(newPhotoData) {
            let path = "\(party.id.uuidString.lowercased())/avatar.jpg"
            PhotoCache.shared.put(prepared, for: path)
            _ = try? await supabase.storage
                .from(SupabaseConfig.partyBucket)
                .upload(path, data: prepared, options: FileOptions(contentType: "image/jpeg", upsert: true))
            newPhotoPath = path
            didChangePhoto = true
        }

        guard finalName != party.name || finalAbout != party.about || finalPublic != party.isPublic || didChangePhoto else {
            return
        }

        do {
            let patch = PartyPatch(
                name: finalName,
                about: finalAbout,
                is_public: finalPublic,
                photo_path: newPhotoPath
            )

            let updated: Party = try await supabase
                .from("parties")
                .update(patch)
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
}
