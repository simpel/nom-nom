import SwiftUI

/// One inbox item: a ListRow (Subject shape) inside the inbox's `Card(layout: .list)`.
/// The leading slot is the meal or recipe photo, the party's Avatar, or the kind's
/// symbol. Unread rows carry ListRow's `unread` dot and semibold title, never a tinted
/// ground (ListRow README). The chevron shows only when the row opens a meal.
struct NotificationRow: View {
    let notification: AppNotification
    var onTap: () -> Void
    var onDelete: () -> Void
    var onToggleRead: () -> Void

    @Environment(FoodStore.self) private var store

    var body: some View {
        ListRow(
            notification.title,
            meta: notification.body,
            leading: notification.listRowLeading(in: store),
            chevron: notification.mealID != nil,
            unread: notification.isUnread,
            action: onTap
        )
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

    private var toggleReadTitle: String {
        notification.isUnread ? "Mark as Read" : "Mark as Unread"
    }

    private var toggleReadSymbol: String {
        notification.isUnread ? "checkmark.circle" : "circle"
    }
}
