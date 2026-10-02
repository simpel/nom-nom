import SwiftUI

/// A dinner party's detail screen on `bg`: cover PhotoStrip, a centred DetailHeader
/// (avatar, name, members · followers · Private, about, Log a meal + Invite for
/// members or Follow for others), a pending-invite banner, the average rating,
/// insights, members and meals. Members get Edit / members / share / leave in the
/// toolbar menu.
struct PartyDetailView: View {
    let partyID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State var showingSettings = false
    @State var showingMembersSheet = false
    @State var showingInvite = false
    @State var showingCreateMeal = false
    @State var confirmLeave = false
    @State var selectedPhotoIndex: Int?
    @State var didAttemptFetch = false
    @State var actionError: String?
    @State var isFollowProcessing = false

    var party: Party? { store.party(partyID) }

    private var partyPhotos: [String] {
        guard let path = party?.photoPath, !path.isEmpty else { return [] }
        return [path]
    }

    var body: some View {
        Group {
            if let party {
                content(for: party)
            } else if !didAttemptFetch {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyState(
                    "Party not found",
                    message: "It may have been deleted, or you no longer have access.",
                    layout: .screen
                )
                .padding(.horizontal, DS.Spacing.gutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.Color.bg)
                .toolbar { closeToolbarItem }
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
                PartyCoverStrip(party: party) { selectedPhotoIndex = $0 }

                header(for: party)

                if !isMember, let pendingInvite {
                    PartyJoinBanner(party: party, invite: pendingInvite) { actionError = $0 }
                }

                PartyAverageRatingCard(party: party)

                PartyInsightsSection(partyID: party.id)

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
        .screenTitle(party.name, displayMode: .inline)
        .toolbar { toolbarContent(for: party) }
        .alert("Leave Party?", isPresented: $confirmLeave) {
            Button("Cancel", role: .cancel) {}
            Button("Leave Party", role: .destructive) { leave(party) }
        } message: {
            Text("You will lose access to meals served to this party. If you are the last member, the party will be deleted.")
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
        .sheet(isPresented: $showingInvite) {
            PartyInviteView(party: party)
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
