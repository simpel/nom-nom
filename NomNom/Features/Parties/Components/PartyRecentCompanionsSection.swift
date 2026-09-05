import SwiftUI

/// Section displaying recent dining companions / eaters with a single-tap invite button.
struct PartyRecentCompanionsSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var invitingID: UUID?
    @State private var invitedIDs: Set<UUID> = []

    private var candidateProfiles: [Profile] {
        store.recentUninvitedProfiles(for: party.id)
    }

    var body: some View {
        if !candidateProfiles.isEmpty {
            SectionCard("Recent Companions") {
                VStack(spacing: 8) {
                    ForEach(Array(candidateProfiles.prefix(5).enumerated()), id: \.element.id) { index, profile in
                        HStack(spacing: 12) {
                            UserAvatar(profile: profile, size: 34)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.shownName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }

                            Spacer()

                            if invitedIDs.contains(profile.id) {
                                Text("Invited")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DS.Color.accentText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(DS.Color.accentSoft)
                                    .clipShape(Capsule())
                            } else if invitingID == profile.id {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button {
                                    invite(profile)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.caption.weight(.bold))
                                        Text("Invite")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(DS.Color.panel)
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(DS.Color.line.opacity(0.4), lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)

                        if index < min(candidateProfiles.count, 5) - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func invite(_ profile: Profile) {
        invitingID = profile.id
        Task {
            let ok = await store.inviteToParty(profile: profile, party: party)
            invitingID = nil
            if ok {
                withAnimation {
                    invitedIDs.insert(profile.id)
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyRecentCompanionsSection(party: party)
                .padding()
        }
    }
}
