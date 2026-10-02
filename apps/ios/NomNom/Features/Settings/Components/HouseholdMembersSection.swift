import SwiftUI

/// Section managing household members, invitations by email, and local household profiles.
struct HouseholdMembersSection: View {

    @Environment(FoodStore.self) private var store

    @State private var email = ""
    @State private var isSending = false
    @State private var successAlertMessage: String?
    @FocusState private var emailFocused: Bool

    private var activeParty: Party? {
        store.currentParty ?? store.myParties.first
    }

    private var partyMembers: [Profile] {
        guard let party = activeParty else { return [] }
        return store.members(of: party.id)
    }

    private var pendingInvites: [PartyInvite] {
        guard let party = activeParty else { return [] }
        return store.invites(forParty: party.id).filter(\.isPending)
    }

    var body: some View {
        EmailInviteCard(
            title: "Add household member",
            placeholder: "member@example.com",
            hint: "They get an email with a link to join your household.",
            email: $email,
            isSending: isSending,
            confirmation: successAlertMessage,
            isFocused: $emailFocused,
            onSend: sendInvite
        )
        .onChange(of: email) { _, newValue in
            if !newValue.isEmpty { successAlertMessage = nil }
        }

        if !partyMembers.isEmpty {
            DSSection("Members", trailing: "\(partyMembers.count)") {
                Card(layout: .list) {
                    ForEach(partyMembers) { member in
                        NavigationLink {
                            PersonDetailView(raterRef: .account(member.id))
                        } label: {
                            ListRow(
                                member.shownName,
                                meta: member.id == store.userID ? "You" : nil,
                                leading: .avatar(Avatar(profile: member, size: .sm, decorative: true)),
                                chevron: true
                            )
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                }
            }
        }

        PartyInvitesSection(invites: pendingInvites)

        if !store.myEaters.isEmpty {
            DSSection("Profiles without an account", trailing: "\(store.myEaters.count)") {
                Card(layout: .list) {
                    ForEach(store.myEaters) { eater in
                        EaterRow(eater: eater)
                    }
                }
            }
        }
    }

    private func sendInvite() {
        let address = email.trimmedName
        guard address.isValidEmail, !isSending else { return }
        isSending = true
        successAlertMessage = nil

        Task {
            let party: Party?
            if let existing = activeParty {
                party = existing
            } else {
                party = await store.createParty(name: "Household")
            }

            guard let targetParty = party else {
                isSending = false
                return
            }

            let ok = await store.inviteToParty(email: address, party: targetParty)
            isSending = false
            if ok {
                let sentEmail = address
                email = ""
                emailFocused = false
                successAlertMessage = "Invite sent to \(sentEmail)."
            }
        }
    }

    private func deleteEater(_ offsets: IndexSet) {
        let doomed = offsets.map { store.myEaters[$0] }
        Task {
            for eater in doomed {
                await store.delete(eater: eater)
            }
        }
    }

    private func moveEater(from source: IndexSet, to destination: Int) {
        var reordered = store.myEaters
        reordered.move(fromOffsets: source, toOffset: destination)
        Task { await store.reorderEaters(reordered) }
    }
}
