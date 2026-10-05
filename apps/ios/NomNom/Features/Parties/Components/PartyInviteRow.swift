import SwiftUI

/// Someone invited to a party who hasn't joined yet, as it sits at the end of every
/// member list: ListRow `inactive` (Avatar `sm`, their name or address and "Invited
/// {when}" at `opacity-50`) with one live "Remind" AppButton `sm` that resends the
/// invite. Revoke is in the row's context menu. DS-GAPS.md A, "ListRow inactive".
///
/// Remind shows a spinner while it sends, then "Reminder sent" or the store's error in
/// the meta line.
struct PartyInviteRow: View {
    let invite: PartyInvite

    @Environment(FoodStore.self) private var store

    private enum Phase { case idle, resending, revoking }

    @State private var phase: Phase = .idle
    @State private var feedback: String?

    private var name: String { store.displayName(for: invite) }

    private var meta: String {
        if let feedback { return feedback }
        guard invite.isPending else { return invite.status.rawValue.capitalized }
        return "Invited \(invite.createdAt.formatted(.relative(presentation: .named)))"
    }

    private var avatar: Avatar {
        if let id = invite.inviteeID, let profile = store.profiles[id] {
            return Avatar(profile: profile, size: .sm, decorative: true)
        }
        return Avatar(name: name, size: .sm, decorative: true)
    }

    var body: some View {
        if invite.isPending {
            ListRow(
                name,
                meta: meta,
                leading: .avatar(avatar),
                trailing: .button(
                    AppButton("Remind", size: .sm, isLoading: phase == .resending) { run(.resending) }
                ),
                chevron: false
            )
            .inactive()
            .accessibilityHint("Invited, hasn\u{2019}t joined yet")
            .contextMenu {
                Button("Revoke invite", systemImage: "xmark", role: .destructive) { run(.revoking) }
            }
        } else {
            ListRow(name, meta: meta, leading: .avatar(avatar)).inactive()
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
                    ? "Couldn\u{2019}t send the reminder."
                    : "Couldn\u{2019}t revoke the invite.")
                store.errorMessage = nil
            } else if next == .resending {
                feedback = "Reminder sent"
            }
            phase = .idle
        }
    }
}
