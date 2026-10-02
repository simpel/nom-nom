import SwiftUI

/// Toolbar button showing a notification bell with an unread dot.
/// The dot is ListRow's unread mark (bundle.css `.nn-row[data-unread]::before`:
/// a `spacing-2` `primary` dot), the one unread signal the DS defines.
struct NotificationBellButton: View {
    @Environment(FoodStore.self) private var store

    @State private var showingInbox = false

    var body: some View {
        Button {
            showingInbox = true
        } label: {
            Image(systemName: "bell")
                .fontWeight(.semibold)
                .overlay(alignment: .topTrailing) {
                    if store.unreadCount > 0 {
                        Circle()
                            .fill(DS.Color.primary)
                            .frame(width: DS.Spacing.s2, height: DS.Spacing.s2)
                            .offset(x: DS.Spacing.s0_5, y: -DS.Spacing.s0_5)
                    }
                }
        }
        .accessibilityLabel(store.unreadCount > 0 ? "\(store.unreadCount) unread notifications" : "Inbox")
        .sheet(isPresented: $showingInbox) {
            InboxSheetView()
        }
    }
}
