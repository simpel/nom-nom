import SwiftUI

/// A dinner party's detail screen on `bg`: a ScreenHeader centred by the party's avatar
/// (name, about, Add meal for members or Follow for others), the landscape cover PhotoStrip, a pending-invite
/// banner, the average rating, the Pro "See insights" card, members and meals.
/// Members get Edit / members / share / leave in the page menu.
struct PartyDetailView: View {
    let partyID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State var showingSettings = false
    @State var showingMembersSheet = false
    @State var showingCreateMeal = false
    @State var showingInsights = false
    @State var confirmLeave = false
    @State var selectedPhotoIndex: Int?
    @State var didAttemptFetch = false
    @State var actionError: String?
    @State var isFollowProcessing = false

    var party: Party? { store.party(partyID) }

    private var partyPhotos: [String] { party?.photoPaths ?? [] }

    var body: some View {
        Group {
            if let party {
                content(for: party)
            } else if !didAttemptFetch {
                ScreenSkeleton(label: "Loading dinner party")
            } else {
                EmptyState(
                    "Party not found",
                    message: "It may have been deleted, or you no longer have access.",
                    layout: .screen
                )
                .padding(.horizontal, DS.Spacing.gutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.Color.bg)
                .modifier(PartyDetailCloseToolbar(isShown: showCloseButton))
            }
        }
        .task(id: partyID) {
            guard party == nil else { return }
            await store.fetchPartyIfMissing(partyID)
            didAttemptFetch = true
        }
    }

    private func content(for party: Party) -> some View {
        let isMember = store.isMember(of: party.id)
        let pendingInvite = store.partyInvites.first {
            $0.partyID == party.id && $0.inviteeID == store.userID && $0.status == .pending
        }

        return ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                header(for: party)

                PartyCoverStrip(party: party) { selectedPhotoIndex = $0 }

                if !isMember, let pendingInvite {
                    PartyJoinBanner(party: party, invite: pendingInvite) { actionError = $0 }
                }

                PartyAverageRatingCard(party: party)

                if isMember {
                    Button {
                        showingInsights = true
                    } label: {
                        ProLinkCard(title: "See insights", subtitle: "Ratings over time, taste match, health and flavours")
                    }
                    .buttonStyle(AppPressableButtonStyle())
                    .sheet(isPresented: $showingInsights) {
                        PartyInsightsView(party: party)
                    }
                }

                if isMember {
                    PartyMembersSection(party: party)
                    PartyMealsSection(party: party)
                } else {
                    PartyMealsSection(party: party)
                    PartyMembersSection(party: party)
                }
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s12)
        }
        .background(DS.Color.bg)
        .screenTitle(showCloseButton ? party.name : "", displayMode: .inline)
        .toolbar { toolbarContent(for: party) }
        .modifier(PartyDetailCloseToolbar(isShown: showCloseButton))
        .alert(store.members(of: party.id).count <= 1 ? "Delete Dinner Party?" : "Leave Party?", isPresented: $confirmLeave) {
            Button("Cancel", role: .cancel) {}
            Button(store.members(of: party.id).count <= 1 ? "Delete Party" : "Leave Party", role: .destructive) { leave(party) }
        } message: {
            if store.members(of: party.id).count <= 1 {
                Text("Since you are the last member, leaving will delete the dinner party.")
            } else {
                Text("You will lose access to meals served to this party.")
            }
        }
        .alert("Something Went Wrong", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("OK") { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
        .sheet(isPresented: $showingSettings) {
            PartySettingsSheet(party: party) {
                dismiss()
            }
        }
        .sheet(isPresented: $showingMembersSheet) {
            PartyMembersSheet(party: party)
        }
        .sheet(isPresented: $showingCreateMeal) {
            MealEditorView(mealID: nil, prefilledPartyID: party.id)
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { wrapper in
            if !partyPhotos.isEmpty {
                MediaViewerSheet(
                    .paths(partyPhotos, bucket: SupabaseConfig.partyBucket),
                    startIndex: wrapper.index,
                    title: "Party"
                )
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
