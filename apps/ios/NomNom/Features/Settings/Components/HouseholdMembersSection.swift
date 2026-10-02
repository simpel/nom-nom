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

    private var isEmailValid: Bool {
        email.isValidEmail
    }

    private var showInvalidFormatError: Bool {
        !email.trimmedName.isEmpty && !email.isValidEmail
    }

    var body: some View {
        SectionCard("Add Household Member") {
            VStack(alignment: .leading, spacing: DS.Spacing.s2_5) {
                HStack(spacing: DS.Spacing.s2) {
                    Input(
                        "member@example.com",
                        text: $email,
                        size: .sm,
                        isError: showInvalidFormatError,
                        isFocused: $emailFocused
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit {
                        if isEmailValid {
                            sendInvite()
                        }
                    }

                    AppButton(
                        "Send",
                        variant: .primary,
                        style: .normal,
                        size: .sm,
                        isPending: isSending,
                        disabled: !isEmailValid || isSending,
                        action: sendInvite
                    )
                }

                if showInvalidFormatError {
                    Text("Please enter a valid email address (e.g. name@example.com).")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.destructiveText)
                } else {
                    Text("Enter an email address. This will send an email with an invite link to join your household.")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
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
            SectionCard("Other Profiles (No account)") {
                VStack(spacing: 0) {
                    ForEach(store.myEaters) { eater in
                        EaterRow(eater: eater)
                        if eater.id != store.myEaters.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func sendInvite() {
        let address = email.trimmedName
        guard !address.isEmpty else { return }
        isSending = true

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
                successAlertMessage = "An email with an invite link was sent to \(sentEmail)."
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
