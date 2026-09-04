import SwiftUI

/// Primary detail view for a dinner party: displays who is in the party,
/// their about description, and what they're eating.
struct PartyDetailView: View {
    let partyID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingSettings = false
    @State private var showingInvite = false
    @State private var showingCreateMeal = false

    private var party: Party? { store.party(partyID) }

    var body: some View {
        Group {
            if let party {
                ScrollView {
                    VStack(spacing: DS.Spacing.section) {
                        PartyDetailHeader(party: party)

                        PartyAverageRatingCard(party: party)

                        PartyMembersSection(party: party)

                        PartyMealsSection(party: party)
                    }
                    .padding(.horizontal, DS.Spacing.screenHorizontal)
                    .padding(.top, DS.Spacing.screenTop)
                    .padding(.bottom, DS.Spacing.screenBottom)
                }
                .background(DS.Color.bg)
                .screenTitle(party.name, displayMode: .inline)
                .toolbar {
                    if showCloseButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("Close")
                        }
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if store.isMember(of: party.id) {
                            Menu {
                                Button {
                                    showingCreateMeal = true
                                } label: {
                                    Label("Create Meal", systemImage: "fork.knife")
                                }

                                Button {
                                    showingInvite = true
                                } label: {
                                    Label("Invite Member", systemImage: "person.badge.plus")
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("Party actions")

                            Button("Edit") {
                                showingSettings = true
                            }
                        } else if party.isPublic {
                            let isFollowing = store.isFollowing(partyID: party.id)
                            Button {
                                Task {
                                    await store.toggleFollow(party: party)
                                }
                            } label: {
                                Image(systemName: isFollowing ? "checkmark" : "plus")
                                    .fontWeight(.semibold)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .accessibilityLabel(isFollowing ? "Unfollow dinner party" : "Follow dinner party")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    PartySettingsSheet(party: party) {
                        dismiss()
                    }
                }
                .sheet(isPresented: $showingInvite) {
                    PartyInviteView(party: party)
                }
                .sheet(isPresented: $showingCreateMeal) {
                    MealEditorView(mealID: nil, prefilledPartyID: party.id)
                }
            } else {
                ContentUnavailableView(
                    "Party Not Found",
                    systemImage: "person.2.slash",
                    description: Text("This dinner party might have been deleted or is no longer accessible.")
                )
                .toolbar {
                    if showCloseButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("Close")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            NavigationStack {
                PartyDetailView(partyID: party.id)
            }
        }
    }
}
