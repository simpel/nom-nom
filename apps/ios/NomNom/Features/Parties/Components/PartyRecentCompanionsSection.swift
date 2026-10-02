import SwiftUI

/// Section displaying recent dining companions / eaters with a single-tap invite button.
struct PartyRecentCompanionsSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var invitingID: UUID?
    @State private var invitedIDs: Set<UUID> = []
    @State private var inviteError: String?

    private var candidateProfiles: [Profile] {
        store.recentUninvitedProfiles(for: party.id)
    }

    var body: some View {
        Group {
            if !candidateProfiles.isEmpty {
                DSSection("Recent companions") {
                    Card(layout: .list) {
                        ForEach(candidateProfiles.prefix(5)) { profile in
                            ListRow(
                                profile.shownName,
                                leading: .avatar(Avatar(profile: profile, size: .sm, decorative: true)),
                                trailing: trailing(for: profile)
                            )
                        }
                    }
                }
            }
        }
        .alert("Couldn't Send Invite", isPresented: Binding(
            get: { inviteError != nil },
            set: { if !$0 { inviteError = nil } }
        )) {
            Button("OK") { inviteError = nil }
        } message: {
            Text(inviteError ?? "")
        }
    }

    /// "Invited" is a status the row now carries (Badge `primary sm`); otherwise
    /// Invite (`primary solid sm`), one request at a time.
    private func trailing(for profile: Profile) -> ListRowTrailing {
        if invitedIDs.contains(profile.id) {
            return .badge(Badge("Invited", size: .sm))
        }
        return .view {
            AppButton("Invite", size: .sm, isLoading: invitingID == profile.id) {
                invite(profile)
            }
            .disabled(invitingID != nil)
        }
    }

    private func invite(_ profile: Profile) {
        invitingID = profile.id
        Task {
            let ok = await store.inviteToParty(profile: profile, party: party)
            invitingID = nil
            if ok {
                withAnimation {
                    _ = invitedIDs.insert(profile.id)
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                inviteError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyRecentCompanionsSection(party: party)
                .padding(DS.Spacing.gutter)
        }
    }
}
