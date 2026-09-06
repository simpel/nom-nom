import SwiftUI

/// Primary detail view for a dinner party: displays who is in the party,
/// their about description, and what they're eating.
struct PartyDetailView: View {
    let partyID: UUID
    var showCloseButton: Bool = false

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingSettings = false
    @State private var showingMembersSheet = false
    @State private var showingInvite = false
    @State private var showingCreateMeal = false
    @State private var confirmLeave = false
    @State private var selectedPhotoIndex: Int?

    private var party: Party? { store.party(partyID) }

    private var partyPhotos: [String] {
        guard let party, let p = party.photoPath, !p.isEmpty else { return [] }
        return [p]
    }

    var body: some View {
        Group {
            if let party {
                ScrollView {
                    VStack(spacing: DS.Spacing.section) {
                        PartyDetailHeader(party: party) { index in
                            selectedPhotoIndex = index
                        }

                        if !store.isMember(of: party.id) {
                            joinPartyBanner(party: party)
                        }

                        PartyAverageRatingCard(party: party)

                        PartyMembersSection(party: party) {
                            showingMembersSheet = true
                        }

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
                            Button {
                                showingCreateMeal = true
                            } label: {
                                Image(systemName: "fork.knife")
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("Create Meal")

                            Button {
                                showingInvite = true
                            } label: {
                                Image(systemName: "person.badge.plus")
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("Add Member")

                            Menu {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button {
                                    showingMembersSheet = true
                                } label: {
                                    Label("Edit members", systemImage: "person.2")
                                }

                                ShareLink(
                                    item: party.inviteURL,
                                    subject: Text("Join \(party.name) on Nom Nom"),
                                    message: Text(party.shareMessage)
                                ) {
                                    Label("Share invite link", systemImage: "square.and.arrow.up")
                                }

                                Button(role: .destructive) {
                                    confirmLeave = true
                                } label: {
                                    Label("Leave party", systemImage: "arrow.right.door")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("Party options")
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
                .alert(
                    "Leave Party?",
                    isPresented: $confirmLeave
                ) {
                    Button("Cancel", role: .cancel) {}
                    Button("Leave Party", role: .destructive) {
                        Task {
                            await store.leaveParty(party)
                            dismiss()
                        }
                    }
                } message: {
                    Text("You will lose access to meals served to this party. If you are the last member, the party will be deleted.")
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
                        MealGalleryViewerSheet(
                            paths: partyPhotos,
                            initialIndex: min(wrapper.index, partyPhotos.count - 1),
                            bucket: SupabaseConfig.partyBucket,
                            titlePrefix: "Party"
                        )
                    }
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

    private func joinPartyBanner(party: Party) -> some View {
        let hasPending = store.partyInvites.contains(where: { $0.partyID == party.id && $0.inviteeID == store.userID && $0.status == .pending })

        return VStack(spacing: 10) {
            Text(hasPending ? "You've been invited to join \(party.name)!" : "Join \(party.name) to share meals and ratings.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)

            AppButton(
                "Join Dinner Party",
                systemImage: "checkmark",
                variant: .secondary,
                style: .normal,
                size: .md,
                isFullWidth: true
            ) {
                Task {
                    if let invite = store.partyInvites.first(where: { $0.partyID == party.id && $0.inviteeID == store.userID && $0.status == .pending }) {
                        await store.acceptPartyInvite(invite)
                    } else {
                        await store.joinParty(party)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
        .padding(14)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.accentText.opacity(0.35), lineWidth: 0.5)
        )
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
