import SwiftUI

/// Toolbar button showing a notification bell with an optional unread counter badge.
struct NotificationBellButton: View {
    @Environment(FoodStore.self) private var store

    @State private var showingInbox = false

    var body: some View {
        Button {
            showingInbox = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .fontWeight(.semibold)
                    .frame(width: 24, height: 24)

                if store.unreadCount > 0 {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .accessibilityLabel(store.unreadCount > 0 ? "\(store.unreadCount) unread notifications" : "Inbox")
        .sheet(isPresented: $showingInbox) {
            InboxSheetView()
        }
    }
}
