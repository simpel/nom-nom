import SwiftUI

/// Comprehensive modal sheet for inviting members to a dinner party via share links, quick-add companions, or email.
struct PartyInviteView: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isSending = false
    @State private var sentSuccessMessage: String?
    @State private var resentAlertMessage: String?
    @FocusState private var focused: Bool

    private var pendingInvites: [PartyInvite] {
        store.invites(forParty: party.id).filter { $0.isPending }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    PartyInviteLinkCard(party: party)

                    PartyRecentCompanionsSection(party: party)

                    emailInviteSection

                    if !pendingInvites.isEmpty {
                        pendingInvitesSection
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Invite to \(party.name)", displayMode: .inline)
            .sheetCloseToolbar()
            .alert("Invitation Resent", isPresented: Binding(
                get: { resentAlertMessage != nil },
                set: { if !$0 { resentAlertMessage = nil } }
            )) {
                Button("OK") { resentAlertMessage = nil }
            } message: {
                Text(resentAlertMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var emailInviteSection: some View {
        SectionCard("Invite by Email") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Input(
                        "friend@example.com",
                        text: $email,
                        size: .sm,
                        isFocused: $focused
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit(sendEmailInvite)

                    AppButton(
                        "Send",
                        variant: .primary,
                        style: .normal,
                        size: .sm,
                        isPending: isSending,
                        disabled: !email.isValidEmail || isSending,
                        action: sendEmailInvite
                    )
                }

                if let success = sentSuccessMessage {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(DS.Color.Pine.pine600)
                        .transition(.opacity)
                } else if !email.trimmedName.isEmpty && !email.isValidEmail {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text("We'll send them a notification and an invitation email to join.")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
    }

    private var pendingInvitesSection: some View {
        SectionCard("Pending Invitations") {
            VStack(spacing: 8) {
                ForEach(Array(pendingInvites.enumerated()), id: \.element.id) { index, invite in
                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(invite.inviteeEmail ?? "Invited member")
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textPrimary)

                            Text("Pending")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.accentText)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            AppButton("Resend", variant: .secondary, style: .outlined, size: .sm) {
                                Task {
                                    let ok = await store.resendPartyInvite(invite)
                                    if ok {
                                        resentAlertMessage = "Invitation resent to \(invite.inviteeEmail ?? "member")."
                                    }
                                }
                            }

                            AppButton(
                                systemImage: "trash",
                                variant: .destructive,
                                style: .ghost,
                                size: .sm
                            ) {
                                Task { await store.revokePartyInvite(invite) }
                            }
                            .accessibilityLabel("Revoke invite")
                        }
                    }
                    .padding(.vertical, 2)

                    if index < pendingInvites.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func sendEmailInvite() {
        let address = email.trimmedName
        guard !address.isEmpty, address.isValidEmail else { return }
        isSending = true
        Task {
            let ok = await store.inviteToParty(email: address, party: party)
            isSending = false
            if ok {
                let invitedEmail = address
                email = ""
                withAnimation {
                    sentSuccessMessage = "Invitation sent to \(invitedEmail)!"
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation {
                        sentSuccessMessage = nil
                    }
                }
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
