import SwiftUI

/// Modal sheet displaying the in-app activity notifications inbox: a ScreenHeader, then
/// "Unread" and "Read" DSSections over `Card(layout: .list)`s of NotificationRows, or a
/// screen EmptyState when there is nothing.
struct InboxSheetView: View {
    @Environment(FoodStore.self) private var store

    private enum InboxSheetDestination: Identifiable {
        case viewMeal(UUID)

        var id: String {
            switch self {
            case .viewMeal(let id): return "view-\(id)"
            }
        }
    }

    @State private var activeDestination: InboxSheetDestination?

    var body: some View {
        NavigationStack {
            SheetBody {
                if store.notifications.isEmpty {
                    EmptyState(
                        "No notifications yet",
                        message: "Invitations, meal ratings and party updates will show up here.",
                        icon: "bell",
                        layout: .screen
                    )
                } else {
                    ScreenHeader("Inbox", summary: headerSubtitle)
                    if !unreadNotifications.isEmpty {
                        // The count stays: it is what the person acts on. "Mark all read" is
                        // this section's one verb, so it left the toolbar.
                        notificationSection(
                            "Unread",
                            trailing: "\(unreadNotifications.count)",
                            action: SectionAction("Mark all read", perform: markAllRead),
                            items: unreadNotifications
                        )
                    }
                    if !readNotifications.isEmpty {
                        notificationSection("Read", trailing: nil, items: readNotifications)
                    }
                }
            }
            .screenTitle("", displayMode: .inline)
            .sheetCloseToolbar()
            .refreshable {
                await store.load()
            }
            .sheet(item: $activeDestination) { destination in
                switch destination {
                case .viewMeal(let mealID):
                    NavigationStack {
                        MealDetailView(mealID: mealID, showCloseButton: true)
                    }
                }
            }
        }
        .dsSheet()
    }

    // MARK: - Subviews

    private var unreadNotifications: [AppNotification] {
        store.notifications.filter(\.isUnread)
    }

    private var readNotifications: [AppNotification] {
        store.notifications.filter { !$0.isUnread }
    }

    private var headerSubtitle: String {
        let unread = store.unreadCount
        if unread > 0 {
            return "\(unread) unread \(unread == 1 ? "notification" : "notifications")."
        }
        return "All caught up on dinner party invites and ratings."
    }

    private func notificationSection(
        _ title: String,
        trailing: String?,
        action: SectionAction? = nil,
        items: [AppNotification]
    ) -> some View {
        DSSection(title, trailing: trailing, trailingTone: .primary, action: action) {
            Card(layout: .list) {
                ForEach(items) { notification in
                    NotificationRow(
                        notification: notification,
                        onTap: { handleNotificationTap(notification) },
                        onDelete: {
                            Task { await store.delete(notification: notification) }
                        },
                        onToggleRead: { toggleRead(notification) }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func markAllRead() {
        Task { await store.markAllRead() }
    }

    private func toggleRead(_ notification: AppNotification) {
        Task {
            if notification.isUnread {
                await store.markRead(notification)
            } else {
                await store.markUnread(notification)
            }
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        if notification.isUnread {
            Task { await store.markRead(notification) }
        }

        if let mealID = notification.mealID {
            // A rating request opens the meal too: rating happens on the meal page.
            activeDestination = .viewMeal(mealID)
        }
    }
}
