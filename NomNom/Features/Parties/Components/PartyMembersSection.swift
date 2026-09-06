import SwiftUI

/// Displays the members of a dinner party ("Who's in there") with their rate scores,
/// navigation to their individual profiles, and an in-page action to edit members.
struct PartyMembersSection: View {
    let party: Party
    var onEditMembers: (() -> Void)? = nil

    @Environment(FoodStore.self) private var store

    private var isMember: Bool {
        store.isMember(of: party.id)
    }

    private var members: [Profile] {
        store.members(of: party.id)
    }

    var body: some View {
        SectionCard("Members") {
            VStack(spacing: 8) {
                if members.isEmpty {
                    Text("No members listed.")
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                        NavigationLink {
                            PersonDetailView(raterRef: .account(member.id))
                        } label: {
                            memberRow(for: member)
                        }
                        .buttonStyle(.plain)

                        if index < members.count - 1 {
                            Divider()
                        }
                    }
                }

                if isMember, let onEditMembers {
                    if !members.isEmpty {
                        Divider()
                    }

                    Button {
                        onEditMembers()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.subheadline)
                            Text("Edit Members")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .foregroundStyle(DS.Color.accentText)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func memberRow(for member: Profile) -> some View {
        let stats = store.partyAverageScore(partyID: party.id, for: .account(member.id), limit: 20)

        return HStack(spacing: 12) {
            UserAvatar(profile: member, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.shownName)
                    .font(.body)
                    .foregroundStyle(DS.Color.textPrimary)

                if member.id == store.userID {
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                } else if member.id == party.createdBy {
                    Text("Creator")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Spacer()

            if let stats {
                ScoreBadge(stats: stats, format: .both, size: .sm)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyMembersSection(party: party)
                .padding()
        }
    }
}
