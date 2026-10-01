// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A party invite in a `Card(layout: .list)`: the invitee's email, its status
/// ("Pending"), and Resend (`primary soft sm`) + revoke (`destructive ghost sm`
/// trash). Each action is async and returns an error message, or nil on success;
/// the row shows its own spinner, "Invitation resent" and errors in the meta line.
///
/// ```swift
/// Card(layout: .list) {
///     ForEach(invites) { PendingInviteRow(invite: $0, store: store) }
/// }
/// ```
struct PendingInviteRow: View {
    let email: String
    var status: String
    /// Show Resend / revoke (false for accepted or declined invites).
    var canAct: Bool
    let resend: () async -> String?
    let revoke: () async -> String?

    private enum Phase { case idle, resending, revoking }
    private enum Feedback { case resent, failed(String) }

    @State private var phase: Phase = .idle
    @State private var feedback: Feedback?

    init(
        email: String,
        status: String = "Pending",
        canAct: Bool = true,
        resend: @escaping () async -> String?,
        revoke: @escaping () async -> String?
    ) {
        self.email = email
        self.status = status
        self.canAct = canAct
        self.resend = resend
        self.revoke = revoke
    }

    private var metaText: String {
        switch feedback {
        case .resent: return "Invitation resent"
        case .failed(let message): return message
        case nil: return status
        }
    }

    private var metaColor: Color {
        switch feedback {
        case .failed: return DS.Color.destructiveText
        case .resent: return DS.Color.primaryText
        case nil: return canAct ? DS.Color.primaryText : DS.Color.textTertiary
        }
    }

    var body: some View {
        if canAct {
            ListRow(email, meta: metaText, metaColor: metaColor, trailing: .view { actions })
        } else {
            ListRow(email, meta: metaText, metaColor: metaColor)
        }
    }

    private var actions: some View {
        HStack(spacing: DS.Spacing.s1) {
            AppButton("Resend", appearance: .soft, size: .sm, isLoading: phase == .resending) {
                run(.resending, resend)
            }
            AppButton(
                icon: "trash",
                accessibilityLabel: "Revoke invite to \(email)",
                variant: .destructive,
                appearance: .ghost,
                size: .sm,
                isLoading: phase == .revoking
            ) {
                run(.revoking, revoke)
            }
        }
        .disabled(phase != .idle)
    }

    private func run(_ next: Phase, _ operation: @escaping () async -> String?) {
        guard phase == .idle else { return }
        phase = next
        feedback = nil
        Task {
            let error = await operation()
            if let error {
                feedback = .failed(error)
            } else if next == .resending {
                feedback = .resent
            }
            phase = .idle
        }
    }
}

extension PendingInviteRow {
    /// Wires a stored invite to FoodStore's resend/revoke, consuming `errorMessage`.
    @MainActor
    init(invite: PartyInvite, store: FoodStore) {
        self.init(
            email: invite.inviteeEmail ?? "Invited member",
            status: invite.status.rawValue.capitalized,
            canAct: invite.isPending,
            resend: {
                if await store.resendPartyInvite(invite) { return nil }
                return Self.takeError(from: store, fallback: "Couldn\u{2019}t resend the invite.")
            },
            revoke: {
                await store.revokePartyInvite(invite)
                guard store.errorMessage != nil else { return nil }
                return Self.takeError(from: store, fallback: "Couldn\u{2019}t revoke the invite.")
            }
        )
    }

    @MainActor
    private static func takeError(from store: FoodStore, fallback: String) -> String {
        let message = store.errorMessage ?? fallback
        store.errorMessage = nil
        return message
    }
}

private struct PendingInviteRowGallery: View {
    var body: some View {
        ScrollView {
            Card(layout: .list) {
                PendingInviteRow(email: "anna@example.com", resend: { nil }, revoke: { nil })
                PendingInviteRow(
                    email: "sam@example.com",
                    resend: { "The invite email couldn\u{2019}t be sent." },
                    revoke: { nil }
                )
                PendingInviteRow(email: "leo@example.com", status: "Accepted", canAct: false, resend: { nil }, revoke: { nil })
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { PendingInviteRowGallery() }
#Preview("Dark") { PendingInviteRowGallery().preferredColorScheme(.dark) }
