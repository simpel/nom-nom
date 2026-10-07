import SwiftUI

/// Step 2 of creating or editing a dinner party: members (first) and sharing & visibility (second).
struct PartySetupStepView: View {
    var partyID: UUID? = nil
    @Bindable var session: FormSession<PartyForm>
    var onCreated: ((Party) -> Void)? = nil

    @Environment(FoodStore.self) private var store

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

            VisibilityToggleCard.party(isPublic: $session.form.isPublic)
        }
        .screenTitle("Party setup", displayMode: .inline)
        .stepCommitToolbar(session, save: save)
    }

    private var membersSection: some View {
        DSSection("Members") {
            Card(layout: .list) {
                if let party {
                    ForEach(store.members(of: party.id)) { member in
                        ListRow(
                            member.shownName,
                            meta: "Member",
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

    private func save(_ form: PartyForm) async throws {
        if let party {
            await store.updateParty(
                party,
                name: form.name.trimmedName,
                about: form.about,
                isPublic: form.isPublic,
                photos: form.photos
            )
            try store.throwIfFailed()
        } else {
            let newParty = await store.createParty(
                name: form.name.trimmedName,
                about: form.about,
                isPublic: form.isPublic,
                photos: form.photos.addedData
            )
            try store.throwIfFailed(newParty != nil)
            if let newParty {
                store.currentParty = newParty
                onCreated?(newParty)
            }
        }
    }
}
