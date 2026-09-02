import SwiftUI

/// Multilevel dropdown menu for settings with My Profile and Dinner Parties as top options.
struct SettingsDropdownMenu: View {
    @Environment(FoodStore.self) private var store

    let onOpenProfile: () -> Void
    let onOpenAllParties: () -> Void
    let onRequestSignOut: () -> Void
    let onRequestDeleteAccount: () -> Void

    var body: some View {
        Menu {
            // MARK: - My Profile
            Menu {
                Button {
                    onOpenProfile()
                } label: {
                    let name = store.myProfile?.shownName ?? "My Name"
                    Label(name.isEmpty ? "Name" : name, systemImage: "person.crop.circle")
                }

                Divider()

                Button(role: .destructive) {
                    onRequestSignOut()
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Button(role: .destructive) {
                    onRequestDeleteAccount()
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
                    onOpenAllParties()
                } label: {
                    Label("All Dinner Parties", systemImage: "person.2")
                }
            } label: {
                Label("Dinner parties", systemImage: "person.2")
            }
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("Settings")
    }
}
