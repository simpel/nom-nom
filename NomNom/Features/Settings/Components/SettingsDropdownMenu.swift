import SwiftUI

/// Dropdown menu for settings with the dinner party switcher up top and a direct button to open the profile sheet.
struct SettingsDropdownMenu: View {
    @Environment(FoodStore.self) private var store

    var onOpenProfile: (() -> Void)? = nil

    @State private var showingProfileSheet = false

    var body: some View {
        Menu {
            // MARK: - Dinner Party Switcher
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
        } label: {
            Image(systemName: "gearshape")
                .fontWeight(.semibold)
        }
        .accessibilityLabel("Settings")
        .sheet(isPresented: $showingProfileSheet) {
            ProfileSheetView()
        }
    }
}
