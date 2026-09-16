import SwiftUI

/// Main Tab — Dinner Parties.
/// Centered on the active dinner party hero experience, with quick party switching,
/// followed dinner circles, and public parties to follow.
struct DinnerPartiesView: View {
    var isSheet: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingCreateSheet = false


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    if !isSheet {
                        PageHeading(title: "Parties", actionTitle: "New party") {
                            showingCreateSheet = true
                        }
                    }

                    PendingPartyInvitesSection()

                    if store.myParties.isEmpty {
                        CurrentPartyHeroView(party: nil) {
                            showingCreateSheet = true
                        }
                    } else {
                        VStack(spacing: DS.Spacing.md) {
                            ForEach(store.myParties) { party in
                                CurrentPartyHeroView(party: party) {
                                    showingCreateSheet = true
                                }
                            }
                        }
                    }

                    FollowedPartiesSection()

                    DiscoverPartiesSection()
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .navigationTitle(isSheet ? "Dinner Parties" : "")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.load()
            }

            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Close")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Create Dinner Party")
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            NotificationBellButton()
                            SettingsDropdownMenu()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreatePartySheet()
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        DinnerPartiesView()
    }
}
