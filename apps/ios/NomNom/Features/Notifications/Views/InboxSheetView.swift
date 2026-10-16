import SwiftUI

/// Modal sheet displaying the in-app activity notifications inbox: a ScreenHeader, then
/// one "Notifications" DSSection over a `Card(layout: .list)` of NotificationRows (unread
/// rows carry the unread dot; state never splits the list), or a screen EmptyState when
/// there is nothing.
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
    @State private var isMarkingAllRead = false

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
                    notificationSection(
                        "Notifications",
                        trailing: store.unreadCount > 0 ? "\(store.unreadCount) unread" : nil,
                        items: store.notifications
                    )
                }
            }
            .screenTitle("", displayMode: .inline)
            .sheetCloseToolbar()
            .toolbar {
                if store.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: markAllRead) {
                            if isMarkingAllRead {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Mark all read").textStyle(.sansSm, weight: .semibold)
                            }
                        }
                        .barItemStyle()
                    }
                }
            }
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

    private var headerSubtitle: String {
        let unread = store.unreadCount
        if unread > 0 {
            return "\(unread) unread \(unread == 1 ? "notification" : "notifications")."
        }
        return "All caught up on dinner party invites and ratings."
    }

    private func notificationSection(_ title: String, trailing: String?, items: [AppNotification]) -> some View {
        DSSection(title, trailing: trailing, trailingTone: .primary) {
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
        isMarkingAllRead = true
        Task {
            await store.markAllRead()
            isMarkingAllRead = false
        }
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
