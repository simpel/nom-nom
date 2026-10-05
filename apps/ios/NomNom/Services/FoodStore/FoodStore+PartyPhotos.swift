import Foundation
import Supabase

extension FoodStore {

    /// Uploads photos to the party bucket under `<party>/<uuid>.jpg` and returns their paths.
    func uploadPartyPhotos(_ photos: [Data], partyID: UUID) async throws -> [String] {
        var paths: [String] = []
        for data in photos {
            guard let prepared = PhotoTools.prepare(data) else { continue }
            let path = "\(partyID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
            _ = try await supabase.storage
                .from(SupabaseConfig.partyBucket)
                .upload(path, data: prepared, options: FileOptions(contentType: "image/jpeg"))
            PhotoCache.shared.put(prepared, for: path)
            paths.append(path)
        }
        return paths
    }

    /// Resolves a photos draft to the party's new `photo_paths`: removed paths are
    /// deleted from storage, added photos uploaded, order kept.
    func resolvePartyPhotos(_ draft: PhotosDraft, for party: Party) async throws -> [String] {
        for path in draft.removedPaths {
            await deletePartyObject(path)
        }
        var paths: [String] = []
        for item in draft.items {
            switch item {
            case .existing(let path):
                if !paths.contains(path) { paths.append(path) }
            case .added(_, let data):
                paths += try await uploadPartyPhotos([data], partyID: party.id)
            }
        }
        return paths
    }

    /// Appends photos to a party (the detail screen's Add photo tile), up to `PhotosDraft.maxCount`.
    func addPartyPhotos(_ photos: [Data], to party: Party) async {
        let room = PhotosDraft.maxCount - party.photoPaths.count
        guard room > 0, !photos.isEmpty else { return }
        do {
            let added = try await uploadPartyPhotos(Array(photos.prefix(room)), partyID: party.id)
            guard !added.isEmpty else { return }
            let updated: Party = try await supabase
                .from("parties")
                .update(PartyPatch(photo_paths: party.photoPaths + added))
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

    /// The party header's avatar pen. A new photo becomes the cover (first in
    /// `photo_paths`); when the party is full, it replaces the old cover. `nil` removes
    /// the cover and the next photo takes its place.
    func setPartyCover(_ data: Data?, for party: Party) async {
        var paths = party.photoPaths
        var dropped: [String] = []
        do {
            if let data {
                let added = try await uploadPartyPhotos([data], partyID: party.id)
                guard !added.isEmpty else { return }
                if paths.count >= PhotosDraft.maxCount, !paths.isEmpty {
                    dropped.append(paths.removeFirst())
                }
                paths = added + paths
            } else {
                guard !paths.isEmpty else { return }
                dropped.append(paths.removeFirst())
            }
            let updated: Party = try await supabase
                .from("parties")
                .update(PartyPatch(photo_paths: paths))
                .eq("id", value: party.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            replaceLocal(party: updated)
            for path in dropped { await deletePartyObject(path) }
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func deletePartyObject(_ path: String) async {
        PhotoCache.shared.forget(path)
        do {
            _ = try await supabase.storage.from(SupabaseConfig.partyBucket).remove(paths: [path])
        } catch {
            Self.log.error("could not remove party photo \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func replaceLocal(party updated: Party) {
        if let idx = parties.firstIndex(where: { $0.id == updated.id }) {
            parties[idx] = updated
        }
        if currentParty?.id == updated.id {
            currentParty = updated
        }
        reindex()
    }
}
