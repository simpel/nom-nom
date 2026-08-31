import SwiftUI

/// A single activity item row in the inbox notifications list.
struct NotificationRow: View {
    let notification: AppNotification

    @Environment(FoodStore.self) private var store

    var body: some View {
        Group {
            if let mealID = notification.mealID, store.meal(mealID) != nil {
                NavigationLink {
                    MealDetailView(mealID: mealID)
                } label: {
                    rowBody
                }
            } else {
                rowBody
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await store.delete(notification: notification) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .task {
            await store.markRead(notification)
        }
    }

    private var rowBody: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: notification.symbol)
                .foregroundStyle(notification.isUnread ? Color.accentColor : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline.weight(notification.isUnread ? .semibold : .regular))
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(notification.createdAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if notification.isUnread {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 2)
    }
}
