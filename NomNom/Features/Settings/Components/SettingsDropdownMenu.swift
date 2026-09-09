import SwiftUI

/// Dropdown menu for settings with the dinner party switcher up top and a direct button to open the profile sheet.
struct SettingsDropdownMenu: View {
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth

    var onOpenProfile: (() -> Void)? = nil

    @State private var showingProfileSheet = false
    @State private var confirmSignOut = false

    var body: some View {
        Menu {
            // MARK: - Dinner Parties Drill-down
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
            } label: {
                Label("Dinner parties", systemImage: "person.2")
            }

            Divider()

            // MARK: - My Profile
            Button {
                if let onOpenProfile {
                    onOpenProfile()
                } else {
                    showingProfileSheet = true
                }
            } label: {
                Label("My profile", systemImage: "person.crop.circle")
            }

            Divider()

            // MARK: - Sign Out
            Button(role: .destructive) {
                confirmSignOut = true
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "gearshape")
                .fontWeight(.semibold)
        }
        .accessibilityLabel("Settings")
        .sheet(isPresented: $showingProfileSheet) {
            ProfileSheetView()
        }
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Sign out", role: .destructive) {
                Task {
                    await store.unregisterCurrentDevice()
                    await auth.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your food log stays on the server and comes back when you sign in again.")
        }
    }
}
