import SwiftUI

/// Multilevel dropdown menu for settings with My Profile and Dinner Parties as top options.
struct SettingsDropdownMenu: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth

    var onOpenProfile: (() -> Void)? = nil
    var onOpenAllParties: (() -> Void)? = nil
    var onRequestSignOut: (() -> Void)? = nil
    var onRequestDeleteAccount: (() -> Void)? = nil

    @State private var activeSheet: SettingsActiveSheet?
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    private enum SettingsActiveSheet: Identifiable {
        case profile
        case allParties
        case inbox

        var id: String {
            switch self {
            case .profile: return "profile"
            case .allParties: return "allParties"
            case .inbox: return "inbox"
            }
        }
    }

    var body: some View {
        Menu {
            Button {
                activeSheet = .inbox
            } label: {
                if store.unreadCount > 0 {
                    Label("Inbox (\(store.unreadCount))", systemImage: "bell.badge")
                } else {
                    Label("Inbox", systemImage: "bell")
                }
            }

            Divider()

            // MARK: - My Profile
            Menu {
                Button {
                    if let onOpenProfile {
                        onOpenProfile()
                    } else {
                        activeSheet = .profile
                    }
                } label: {
                    let name = store.myProfile?.shownName ?? "My Name"
                    Label(name.isEmpty ? "Name" : name, systemImage: "person.crop.circle")
                }

                Divider()

                Button(role: .destructive) {
                    if let onRequestSignOut {
                        onRequestSignOut()
                    } else {
                        confirmSignOut = true
                    }
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Button(role: .destructive) {
                    if let onRequestDeleteAccount {
                        onRequestDeleteAccount()
                    } else {
                        confirmDelete = true
                    }
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
            } label: {
                Label("My profile", systemImage: "person.crop.circle")
            }

            // MARK: - Dinner Parties
            Menu {
                Picker("Dinner party", selection: Binding(
                    get: { store.currentParty?.id },
                    set: { selectedID in
                        if let selectedID, let party = store.party(selectedID) {
                            store.currentParty = party
                        } else {
                            store.currentParty = nil
                        }
                    }
                )) {
                    Text("Just me").tag(nil as UUID?)
                    ForEach(store.myParties) { party in
                        Text(party.name).tag(party.id as UUID?)
                    }
                }

                Divider()

                Button {
                    if let onOpenAllParties {
                        onOpenAllParties()
                    } else {
                        activeSheet = .allParties
                    }
                } label: {
                    Label("All Dinner Parties", systemImage: "person.2")
                }
            } label: {
                Label("Dinner parties", systemImage: "person.2")
            }
        } label: {
            Image(systemName: "gearshape")
                .fontWeight(.semibold)
        }
        .accessibilityLabel("Settings")
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .profile:
                NavigationStack {
                    PersonDetailView(raterRef: .account(store.userID), isSheet: true)
                }
            case .allParties:
                NavigationStack {
                    PartyListView(isSheet: true)
                }
            case .inbox:
                InboxSheetView()
            }
        }
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your food log stays on the server and comes back when you sign in again.")
        }
        .alert("Delete your account?", isPresented: $confirmDelete) {
            Button("Delete everything", role: .destructive) {
                Task { await auth.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your account, every meal and photo you've logged, and the people you track. It cannot be undone.")
        }
        .alert("Couldn't delete your account",
               isPresented: Binding(get: { auth.errorMessage != nil },
                                    set: { if !$0 { auth.errorMessage = nil } })) {
            Button("OK") { auth.errorMessage = nil }
        } message: {
            Text(auth.errorMessage ?? "")
        }
    }
}
