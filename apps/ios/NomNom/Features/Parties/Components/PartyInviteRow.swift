import SwiftUI

/// One party invite: ListRow's Invite shape (components/ListRow/README.md). Avatar `sm`
/// from the address, the email, "Invited {when}", Resend (`secondary ghost sm`) and the
/// revoke ✕ (`destructive ghost` icon-only). Place it in `PartyInvitesSection`.
///
/// Resend and revoke are async; the row shows a spinner on the pressed button, then
/// "Invitation resent" or the store's error in the meta line.
struct PartyInviteRow: View {
    let invite: PartyInvite

    @Environment(FoodStore.self) private var store

    private enum Phase { case idle, resending, revoking }

    @State private var phase: Phase = .idle
    @State private var feedback: String?

    private var email: String { invite.inviteeEmail ?? "Invited member" }

    private var meta: String {
        if let feedback { return feedback }
        guard invite.isPending else { return invite.status.rawValue.capitalized }
        return "Invited \(invite.createdAt.formatted(.relative(presentation: .named)))"
    }

    var body: some View {
        if invite.isPending {
            ListRow(
                email,
                meta: meta,
                leading: .avatar(Avatar(name: email, size: .sm, decorative: true)),
                trailing: .button(
                    AppButton("Resend", variant: .secondary, appearance: .ghost, size: .sm,
                              isLoading: phase == .resending) { run(.resending) }
                ),
                trailingAction: ListRowIconAction(
                    icon: "xmark",
                    accessibilityLabel: "Revoke invite to \(email)",
                    isLoading: phase == .revoking
                ) { run(.revoking) },
                chevron: false
            )
            .disabled(phase != .idle)
        } else {
            ListRow(email, meta: meta, leading: .avatar(Avatar(name: email, size: .sm, decorative: true)))
        }
    }

    private func run(_ next: Phase) {
        guard phase == .idle else { return }
        phase = next
        feedback = nil
        Task {
            let failed: Bool
            if next == .resending {
                failed = !(await store.resendPartyInvite(invite))
            } else {
                await store.revokePartyInvite(invite)
                failed = store.errorMessage != nil
            }
            if failed {
                feedback = store.errorMessage ?? (next == .resending
                    ? "Couldn\u{2019}t resend the invite."
                    : "Couldn\u{2019}t revoke the invite.")
                store.errorMessage = nil
            } else if next == .resending {
                feedback = "Invitation resent"
            }
            phase = .idle
        }
    }
}
