import Foundation
import Supabase

extension FoodStore {

    @discardableResult
    func createParty(
        name: String,
        about: String = "",
        isPublic: Bool = false,
        photoData: Data? = nil
    ) async -> Party? {
        let trimmed = name.trimmedName
        guard !trimmed.isEmpty else { return nil }
        do {
            let partyID = UUID()
            var uploadedPath: String? = nil

            if let photoData, let prepared = PhotoTools.prepare(photoData) {
                let path = "\(partyID.uuidString.lowercased())/avatar.jpg"
                PhotoCache.shared.put(prepared, for: path)
                _ = try? await supabase.storage
                    .from(SupabaseConfig.partyBucket)
                    .upload(path, data: prepared, options: FileOptions(contentType: "image/jpeg", upsert: true))
                uploadedPath = path
            }

            let created: Party = try await supabase
                .from("parties")
                .insert(NewParty(
                    id: partyID,
                    name: trimmed,
                    about: about.trimmingCharacters(in: .whitespacesAndNewlines),
                    is_public: isPublic,
                    photo_path: uploadedPath,
                    created_by: userID
                ))
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
}

