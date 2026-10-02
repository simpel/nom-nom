import SwiftUI

/// One inbox item: a ListRow (Subject shape) inside the inbox's `Card(layout: .list)`.
/// The leading slot is the meal or recipe photo, the party's Avatar, or the kind's
/// symbol. Rows carry no `unread` dot: the inbox's "Unread" section already says it,
/// and the dot crowded the invite buttons. The chevron shows only when the row opens a meal.
/// A party invite still pending carries Accept (`primary solid sm`) and Decline
/// (`secondary soft sm`), as in PendingPartyInvitesSection (ListRow README: "two
/// labelled buttons").
struct NotificationRow: View {
    let notification: AppNotification
    var onTap: () -> Void
    var onDelete: () -> Void
    var onToggleRead: () -> Void

    @Environment(FoodStore.self) private var store

    private var pendingInvite: PartyInvite? {
        guard notification.kind == .partyInvite, let partyID = notification.partyID else { return nil }
        return store.pendingInvite(toParty: partyID)
    }

    var body: some View {
        row
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onToggleRead) {
                Label(toggleReadTitle, systemImage: toggleReadSymbol)
            }
            .tint(DS.Color.primary)
        }
        .contextMenu {
            Button(action: onToggleRead) {
                Label(toggleReadTitle, systemImage: toggleReadSymbol)
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var row: some View {
        if let invite = pendingInvite {
            ListRow(
                notification.title,
                meta: notification.body,
                leading: notification.listRowLeading(in: store),
                trailing: .view {
                    HStack(spacing: DS.Spacing.s2) {
                        AppButton("Accept", size: .sm) { respond(to: invite, accept: true) }
                        AppButton("Decline", variant: .secondary, appearance: .soft, size: .sm) {
                            respond(to: invite, accept: false)
                        }
                    }
                }
            )
        } else {
            ListRow(
                notification.title,
                meta: notification.body,
                leading: notification.listRowLeading(in: store),
                chevron: notification.mealID != nil,
                action: onTap
            )
        }
    }

    private func respond(to invite: PartyInvite, accept: Bool) {
        Task {
            if accept {
                await store.acceptPartyInvite(invite)
            } else {
                await store.declinePartyInvite(invite)
            }
            if notification.isUnread { await store.markRead(notification) }
        }
    }

    private var toggleReadTitle: String {
        notification.isUnread ? "Mark as Read" : "Mark as Unread"
    }

    private var toggleReadSymbol: String {
        notification.isUnread ? "checkmark.circle" : "circle"
    }
}
