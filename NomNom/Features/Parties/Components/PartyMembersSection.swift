import SwiftUI

/// Displays the members of a dinner party ("Who's in there") with their rate scores,
/// and navigation to their individual profiles.
struct PartyMembersSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var members: [Profile] {
        store.members(of: party.id)
    }

    @State private var memberToRemove: Profile?

    var body: some View {
        SwipeableListCard(
            title: "Members",
            data: members,
            dividerPadding: 60,
            leadingIcon: { canRemove(member: $0) ? "trash.fill" : nil },
            leadingColor: { canRemove(member: $0) ? .red : nil },
            onLeadingAction: { member in
                if canRemove(member: member) {
                    memberToRemove = member
                }
            }
        ) { member in
            NavigationLink {
                PersonDetailView(raterRef: .account(member.id))
            } label: {
                memberRow(for: member)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
        .alert(
            "Remove Member?",
            isPresented: Binding(
                get: { memberToRemove != nil },
                set: { if !$0 { memberToRemove = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                memberToRemove = nil
            }
            if let member = memberToRemove {
                Button("Remove \(member.shownName)", role: .destructive) {
                    Task {
                        await store.removeMember(user: member.id, from: party)
                    }
                }
            }
        } message: {
            if let member = memberToRemove {
                Text("\(member.shownName) will lose access to meals and ratings in this dinner party.")
            }
        }
    }

    private func canRemove(member: Profile) -> Bool {
        store.isMember(of: party.id) && member.id != store.userID
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
        }
        .padding(.vertical, DS.Spacing.sm)
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
