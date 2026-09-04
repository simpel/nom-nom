import SwiftUI

/// Modal sheet displaying the in-app activity notifications inbox.
struct InboxSheetView: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private enum InboxSheetDestination: Identifiable {
        case rate(UUID)
        case viewMeal(UUID)

        var id: String {
            switch self {
            case .rate(let id): return "rate-\(id)"
            case .viewMeal(let id): return "view-\(id)"
            }
        }
    }

    @State private var activeDestination: InboxSheetDestination?
    @State private var isMarkingAllRead = false

    var body: some View {
        NavigationStack {
            Group {
                if store.notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .background(DS.Color.bg)
            .screenTitle("", displayMode: .inline)
            .sheetCloseToolbar()
            .toolbar {
                if store.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isMarkingAllRead = true
                            Task {
                                await store.markAllRead()
                                isMarkingAllRead = false
                            }
                        } label: {
                            if isMarkingAllRead {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Mark All Read")
                                    .font(.inter(.footnote, weight: .medium))
                                    .foregroundStyle(DS.Color.accentText)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await store.load()
            }
            .sheet(item: $activeDestination) { destination in
                switch destination {
                case .rate(let mealID):
                    MealRatingSheet(mealID: mealID)
                case .viewMeal(let mealID):
                    NavigationStack {
                        MealDetailView(mealID: mealID, showCloseButton: true)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.section) {
                InboxHeaderView(unreadCount: store.unreadCount, totalCount: store.notifications.count)

                ContentUnavailableView(
                    "No Notifications",
                    systemImage: "bell.slash",
                    description: Text("You're all caught up. Invitations and meal ratings will appear here.")
                )
                .padding(.top, 40)
            }
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
    }

    private var unreadNotifications: [AppNotification] {
        store.notifications.filter(\.isUnread)
    }

    private var readNotifications: [AppNotification] {
        store.notifications.filter { !$0.isUnread }
    }

    private var notificationsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                InboxHeaderView(unreadCount: store.unreadCount, totalCount: store.notifications.count)

                if !unreadNotifications.isEmpty {
                    notificationSection(
                        title: "Unread",
                        badge: "\(unreadNotifications.count)",
                        items: unreadNotifications
                    )
                }

                if !readNotifications.isEmpty {
                    notificationSection(
                        title: "Read",
                        badge: nil,
                        items: readNotifications
                    )
                }
            }
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
    }

    private func notificationSection(title: String, badge: String?, items: [AppNotification]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title,
                trailingText: badge,
                trailingColor: DS.Color.accentText,
                horizontalPadding: DS.Spacing.screenHorizontal
            )

            LazyVStack(spacing: 8) {
                ForEach(items) { notification in
                    NotificationRow(
                        notification: notification,
                        onTap: { handleNotificationTap(notification) },
                        onDelete: {
                            Task { await store.delete(notification: notification) }
                        },
                        onToggleRead: {
                            Task {
                                if notification.isUnread {
                                    await store.markRead(notification)
                                } else {
                                    await store.markUnread(notification)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
        }
    }

    // MARK: - Actions

    private func handleNotificationTap(_ notification: AppNotification) {
        if notification.isUnread {
            Task { await store.markRead(notification) }
        }

        if let mealID = notification.mealID {
            if notification.kind == .ratingRequest {
                activeDestination = .rate(mealID)
            } else {
                activeDestination = .viewMeal(mealID)
            }
        }
    }
}
