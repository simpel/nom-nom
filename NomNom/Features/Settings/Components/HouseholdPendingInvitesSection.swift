import SwiftUI

/// Section in Settings displaying pending party invitations with resend and revoke options.
struct HouseholdPendingInvitesSection: View {
    let pendingInvites: [PartyInvite]
    @Binding var successAlertMessage: String?

    @Environment(FoodStore.self) private var store

    var body: some View {
        if !pendingInvites.isEmpty {
            Section {
                ForEach(pendingInvites) { invite in
                    inviteRow(for: invite)
                }
            } header: {
                Text("Pending Invitations")
            }
        }
    }

    private func inviteRow(for invite: PartyInvite) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(invite.inviteeEmail ?? "Invited member")
                    .font(.subheadline.weight(.medium))
                Text("Invite link sent • Pending")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Resend") {
                    resend(invite)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Menu {
                    Button {
                        resend(invite)
                    } label: {
                        Label("Resend Invite", systemImage: "paperplane")
                    }

                    Button(role: .destructive) {
                        revoke(invite)
                    } label: {
                        Label("Revoke Invite", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                revoke(invite)
            } label: {
                Label("Revoke", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                resend(invite)
            } label: {
                Label("Resend", systemImage: "paperplane")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                resend(invite)
            } label: {
                Label("Resend Invite", systemImage: "paperplane")
            }

            Button(role: .destructive) {
                revoke(invite)
            } label: {
                Label("Revoke Invite", systemImage: "trash")
            }
        }
    }

    private func resend(_ invite: PartyInvite) {
        Task {
            let success = await store.resendPartyInvite(invite)
            if success {
                successAlertMessage = "Invitation resent to \(invite.inviteeEmail ?? "member")."
            }
        }
    }

    private func revoke(_ invite: PartyInvite) {
        Task { await store.revokePartyInvite(invite) }
    }
}
