import SwiftUI

/// Main Tab — Dinner Parties.
/// Three dedicated views: My Parties (joined & invites), Following, and Discover.
struct DinnerPartiesView: View {
    var isSheet: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: PartyTab = .myParties
    @State private var showingCreateSheet = false

    enum PartyTab: String, CaseIterable, Identifiable {
        case myParties = "My Parties"
        case following = "Following"
        case discover = "Discover"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    // Minimal 3-segment filter: My Parties | Following | Discover
                    Picker("View", selection: $selectedTab) {
                        ForEach(PartyTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    switch selectedTab {
                    case .myParties:
                        myPartiesContent
                    case .following:
                        followingContent
                    case .discover:
                        discoverContent
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("Dinner Parties")
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
                            CreateDropdownMenu()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreatePartySheet()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var myPartiesContent: some View {
        PendingPartyInvitesSection()

        if store.myParties.isEmpty {
            SectionCard("Joined") {
                Text("No dinner parties yet. Tap + to create one.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            VStack(spacing: DS.Spacing.md) {
                ForEach(store.myParties) { party in
                    PartyCard(party: party)
                }
            }
        }
    }

    @ViewBuilder
    private var followingContent: some View {
        let followed = store.followedParties
        if followed.isEmpty {
            SectionCard("Following") {
                Text("You are not following any dinner parties yet. Explore Discover to find parties to follow.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            VStack(spacing: DS.Spacing.md) {
                ForEach(followed) { party in
                    PartyCard(party: party)
                }
            }
        }
    }

    @ViewBuilder
    private var discoverContent: some View {
        let discoverable = store.discoverParties
        if discoverable.isEmpty {
            SectionCard("Discover") {
                Text("No new public dinner parties found right now.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            VStack(spacing: DS.Spacing.md) {
                ForEach(discoverable) { party in
                    PartyCard(party: party)
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { _ in
        DinnerPartiesView()
    }
}
