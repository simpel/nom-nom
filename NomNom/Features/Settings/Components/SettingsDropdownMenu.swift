import SwiftUI

/// Multilevel dropdown menu for settings with My Profile and Dinner Parties as top options.
struct SettingsDropdownMenu: View {
    @Environment(FoodStore.self) private var store

    let onOpenProfile: () -> Void
    let onOpenPartyDetail: (Party) -> Void
    let onOpenHouseholdMembers: () -> Void
    let onOpenCreateParty: () -> Void
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
                if let party = store.currentParty {
                    Button {
                        onOpenPartyDetail(party)
                    } label: {
                        Label("\(party.name) Settings & Members", systemImage: "person.2.badge.gearshape")
                    }

                    let members = store.members(of: party.id)
                    if !members.isEmpty {
                        Menu {
                            ForEach(members) { member in
                                Label("\(member.avatarEmoji) \(member.shownName)", systemImage: member.id == store.userID ? "person.fill" : "person")
                            }
                        } label: {
                            Label("Members (\(members.count))", systemImage: "person.2")
                        }
                    }

                    Divider()
                } else {
                    Button {
                        onOpenHouseholdMembers()
                    } label: {
                        Label("Household Members", systemImage: "person.3")
                    }

                    Divider()
                }

                Button {
                    onOpenCreateParty()
                } label: {
                    Label("New Dinner Party", systemImage: "plus")
                }

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
