import SwiftUI

/// Tab 4 — what other people want from you, and what they thought of your food.
///
/// Features pending dinner party invites, meals waiting for your rating, and recent notifications.
struct InboxView: View {
    @Environment(FoodStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.pendingPartyInvites.isEmpty && store.awaitingMyRating.isEmpty && store.notifications.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing waiting", systemImage: "tray")
                    } description: {
                        Text("When somebody invites you to a dinner party, asks for a rating, or rates your food, it shows up here.")
                    }
                } else {
                    List {
                        if !store.pendingPartyInvites.isEmpty {
                            Section("Dinner Party Invitations") {
                                ForEach(store.pendingPartyInvites) { invite in
                                    PendingPartyInviteCard(invite: invite)
                                }
                            }
                        }

                        if !store.awaitingMyRating.isEmpty {
                            Section {
                                ForEach(store.awaitingMyRating) { meal in
                                    PendingRatingCard(meal: meal)
                                }
                            } header: {
                                Text("Waiting for your verdict")
                            }
                        }

                        if !store.notifications.isEmpty {
                            Section {
                                ForEach(store.notifications) { note in
                                    NotificationRow(notification: note)
                                }
                            } header: {
                                HStack {
                                    Text("Recent")
                                    Spacer()
                                    if store.unreadCount > 0 {
                                        Button("Mark all read") {
                                            Task { await store.markAllRead() }
                                        }
                                        .font(.caption)
                                        .textCase(nil)
                                    }
                                }
                            }
                        }
                    }
                    .refreshable { await store.load() }
                }
            }
            .navigationTitle("Inbox")
        }
    }
}
