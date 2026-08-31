import SwiftUI

/// Section managing household members, invitations by email, and local household profiles.
struct HouseholdMembersSection: View {
    var emojiChoices: [String] = ["🧒", "👦", "👧", "🧑", "👩", "👨", "👶", "🐣", "🦊", "🐻", "🐼", "🦁", "🐧", "🦄"]

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
        // MARK: - Add Household Member by Email
        Section {
            HStack(spacing: 8) {
                TextField("member@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($emailFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if isEmailValid {
                            sendInvite()
                        }
                    }

                if isSending {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Send", action: sendInvite)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!isEmailValid || isSending)
                }
            }
        } header: {
            Text("Add Household Member")
        } footer: {
            if showInvalidFormatError {
                Text("Please enter a valid email address (e.g. name@example.com).")
                    .foregroundStyle(.red)
            } else {
                Text("Enter an email address. This will send an email with an invite link to join your household.")
            }
        }

        // MARK: - Active Household Members
        if !partyMembers.isEmpty {
            Section {
                ForEach(partyMembers) { member in
                    HStack(spacing: 12) {
                        Text(member.avatarEmoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.shownName)
                                .font(.body)
                            if member.id == store.userID {
                                Text("You")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Members (\(partyMembers.count))")
            }
        }

        // MARK: - Pending Email Invitations
        if !pendingInvites.isEmpty {
            Section {
                ForEach(pendingInvites) { invite in
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.badge")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(invite.inviteeEmail ?? "Invited member")
                                .font(.subheadline.weight(.medium))
                            Text("Invite link sent • Pending")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Revoke", role: .destructive) {
                            Task { await store.revokePartyInvite(invite) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Pending Invitations")
            }
        }

        // MARK: - Local Eaters (If any exist)
        if !store.myEaters.isEmpty {
            Section {
                ForEach(store.myEaters) { eater in
                    EaterRow(eater: eater, emojiChoices: emojiChoices)
                }
                .onDelete(perform: deleteEater)
                .onMove(perform: moveEater)
            } header: {
                Text("Other Profiles (No account)")
            }
        }
    }

    private func sendInvite() {
        let address = email.trimmedName
        guard !address.isEmpty else { return }
        isSending = true

        Task {
            // Find existing party or create a default household party if none exists yet
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

struct EaterRow: View {
    let eater: Eater
    let emojiChoices: [String]

    @Environment(FoodStore.self) private var store

    @State private var name: String

    init(eater: Eater, emojiChoices: [String]) {
        self.eater = eater
        self.emojiChoices = emojiChoices
        self._name = State(initialValue: eater.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(emojiChoices, id: \.self) { emoji in
                    Button(emoji) { commit { $0.emoji = emoji } }
                }
            } label: {
                Text(eater.emoji).font(.title2)
            }

            TextField("Name", text: $name)
                .onSubmit { commit { $0.name = name } }
        }
        .onChange(of: eater.name) { _, updated in
            if updated != name { name = updated }
        }
    }

    private func commit(_ change: (inout Eater) -> Void) {
        var updated = eater
        updated.name = name.trimmedName.isEmpty ? eater.name : name.trimmedName
        change(&updated)
        Task { await store.update(eater: updated) }
    }
}
