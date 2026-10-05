import SwiftUI

/// Step 2 of creating or editing a dinner party: members (first) and sharing & visibility (second).
struct PartySetupStepView: View {
    var partyID: UUID? = nil
    let name: String
    let about: String
    let photoDraft: FoodStore.PhotosDraft
    @Binding var isPublic: Bool
    var onCreated: ((Party) -> Void)? = nil
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool { partyID != nil }
    private var party: Party? { partyID.flatMap { store.party($0) } }
    private var invites: [PartyInvite] {
        guard let partyID else { return [] }
        return store.pendingInvites(forParty: partyID)
    }

    var body: some View {
        SheetBody {
            if let party {
                PartyInviteLinkCard(party: party)
            }

            membersSection

            VisibilityToggleCard.party(isPublic: $isPublic)
        }
        .screenTitle("Party setup", displayMode: .inline)
        .stepCommitToolbar(isSaving: isSaving, onSave: save)
        .alert("Couldn't save dinner party",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var membersSection: some View {
        DSSection("Members") {
            Card(layout: .list) {
                if let party {
                    ForEach(store.members(of: party.id)) { member in
                        ListRow(
                            member.shownName,
                            meta: member.id == party.createdBy ? "Host" : "Member",
                            leading: .avatar(Avatar(profile: member, size: .sm, decorative: true))
                        )
                    }
                    ForEach(invites) { PartyInviteRow(invite: $0) }
                } else {
                    // One line of meta (ListRow README); invites open once the party exists.
                    ListRow(
                        "You",
                        meta: "Host \u{00B7} invite people once the party is created",
                        leading: .avatar(Avatar(name: store.myProfile?.shownName ?? "You", size: .sm, decorative: true))
                    )
                }
            }
        }
    }

    private func save() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            if let party {
                await store.updateParty(
                    party,
                    name: partyName,
                    about: about,
                    isPublic: isPublic,
                    photos: photoDraft
                )
                isSaving = false
                if store.errorMessage == nil {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onDismiss()
                } else {
                    errorMessage = store.errorMessage
                    store.errorMessage = nil
                }
            } else {
                if let newParty = await store.createParty(
                    name: partyName,
                    about: about,
                    isPublic: isPublic,
                    photos: photoDraft.addedData
                ) {
                    store.currentParty = newParty
                    onCreated?(newParty)
                    isSaving = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onDismiss()
                } else {
                    errorMessage = store.errorMessage ?? "An error occurred creating the party."
                    isSaving = false
                }
            }
        }
    }
}
