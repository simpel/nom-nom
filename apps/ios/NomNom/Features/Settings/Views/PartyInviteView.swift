import SwiftUI

/// Comprehensive modal sheet for inviting members to a dinner party via share links, quick-add companions, or email.
struct PartyInviteView: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isSending = false
    @State private var sentSuccessMessage: String?
    @State private var inviteError: String?
    @FocusState private var focused: Bool

    private var pendingInvites: [PartyInvite] {
        store.invites(forParty: party.id).filter { $0.isPending }
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                PartyInviteLinkCard(party: party)

                PartyRecentCompanionsSection(party: party)

                emailInviteSection

                PartyInvitesSection(invites: pendingInvites)
            }
            .screenTitle("Invite to \(party.name)", displayMode: .inline)
            .sheetCloseToolbar()
            .alert("Couldn't send invite", isPresented: Binding(
                get: { inviteError != nil },
                set: { if !$0 { inviteError = nil } }
            )) {
                Button("OK") { inviteError = nil }
            } message: {
                Text(inviteError ?? "")
            }
        }
        .dsSheet()
    }

    // MARK: - Sections

    private var emailInviteSection: some View {
        EmailInviteCard(
            title: "Invite by email",
            placeholder: "friend@example.com",
            hint: "They get a notification and an email inviting them to join.",
            email: $email,
            isSending: isSending,
            confirmation: sentSuccessMessage,
            isFocused: $focused,
            onSend: sendEmailInvite
        )
    }

    // MARK: - Actions

    private func sendEmailInvite() {
        let address = email.trimmedName
        guard !address.isEmpty, address.isValidEmail, !isSending else { return }
        isSending = true
        Task {
            let ok = await store.inviteToParty(email: address, party: party)
            isSending = false
            if ok {
                let invitedEmail = address
                email = ""
                withAnimation(DS.Motion.state) {
                    sentSuccessMessage = "Invite sent to \(invitedEmail)."
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation(DS.Motion.state) {
                        sentSuccessMessage = nil
                    }
                }
            } else {
                inviteError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyInviteView(party: party)
        }
    }
}
