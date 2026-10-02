import SwiftUI

/// The party's members as ListRows (Avatar, name, You / Creator, their average score)
/// in a swipeable list card. Members can swipe another member's row to remove them.
struct PartyMembersSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var memberToRemove: Profile?

    private var members: [Profile] {
        store.members(of: party.id)
    }

    var body: some View {
        // SwipeableListCard draws the section header, the list Card and the row padding.
        SwipeableListCard(
            title: "Members",
            data: members,
            leadingIcon: { canRemove(member: $0) ? "trash.fill" : nil },
            leadingColor: { canRemove(member: $0) ? DS.Color.destructive : nil },
            onLeadingAction: { member in
                if canRemove(member: member) {
                    memberToRemove = member
                }
            }
        ) { member in
            NavigationLink {
                PersonDetailView(raterRef: .account(member.id))
            } label: {
                row(for: member)
            }
            .buttonStyle(ListRowButtonStyle())
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

    private func role(of member: Profile) -> String? {
        if member.id == store.userID { return "You" }
        if member.id == party.createdBy { return "Creator" }
        return nil
    }

    private func row(for member: Profile) -> ListRow {
        let stats = store.partyAverageScore(partyID: party.id, for: .account(member.id), limit: 20)
        return ListRow(
            member.shownName,
            meta: role(of: member),
            leading: .avatar(Avatar(profile: member, size: .sm)),
            trailing: stats.map { .score($0.score) },
            chevron: true
        )
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyMembersSection(party: party)
                .padding(DS.Spacing.gutter)
        }
    }
}
