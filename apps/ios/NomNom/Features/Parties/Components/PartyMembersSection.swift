import SwiftUI

/// The party's members ("Nom Nom iOS" canvas): a "Members" section over one swipeable
/// list card. Members see an "Add members" row first (opens the invite sheet); each
/// member row (Avatar, name, "You · 20 rated here", their average score) opens the
/// member sheet. Members can swipe another member's row to remove them. Members also see
/// everyone invited who hasn't joined, last, as inactive PartyInviteRows with Remind.
struct PartyMembersSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @State private var memberToRemove: Profile?
    @State private var selectedMember: MemberSheetTarget?

    private enum Item: Identifiable {
        case add
        case member(Profile)
        case invite(PartyInvite)

        var id: String {
            switch self {
            case .add: return "add"
            case .member(let profile): return profile.id.uuidString
            case .invite(let invite): return "invite_\(invite.id.uuidString)"
            }
        }
    }

    private struct MemberSheetTarget: Identifiable {
        let id: UUID
    }

    private var members: [Profile] { store.members(of: party.id) }
    private var isMember: Bool { store.isMember(of: party.id) }

    private var items: [Item] {
        let invites = isMember ? store.pendingInvites(forParty: party.id).map(Item.invite) : []
        return members.map(Item.member) + invites + (isMember ? [.add] : [])
    }

    var body: some View {
        SwipeableListCard(
            title: "Members",
            caption: "\(members.count)",
            data: items,
            leadingIcon: { item in removable(item) != nil ? "trash.fill" : nil },
            leadingColor: { item in removable(item) != nil ? DS.Color.destructive : nil },
            onLeadingAction: { item in memberToRemove = removable(item) }
        ) { item in
            switch item {
            case .add:
                    ShareLink(
                        item: party.webInviteURL,
                        subject: Text("Join \(party.name) on Nom Nom"),
                        message: Text(party.shareMessage)
                    ) {
                        ListRow("Add members", meta: "Share the invite link", leading: .icon("plus"), chevron: false)
                    }
                    .buttonStyle(AppPressableButtonStyle())
                case .member(let member):
                    row(for: member)
                case .invite(let invite):
                    PartyInviteRow(invite: invite)
                }
            }
        .sheet(item: $selectedMember) { target in
            PartyMemberInsightSheet(memberRef: .account(target.id), partyID: party.id)
        }
        .alert(
            "Remove Member?",
            isPresented: Binding(get: { memberToRemove != nil }, set: { if !$0 { memberToRemove = nil } })
        ) {
            Button("Cancel", role: .cancel) { memberToRemove = nil }
            if let member = memberToRemove {
                Button("Remove \(member.shownName)", role: .destructive) {
                    Task { await store.removeMember(user: member.id, from: party) }
                }
            }
        } message: {
            if let member = memberToRemove {
                Text("\(member.shownName) will lose access to meals and ratings in this dinner party.")
            }
        }
    }

    private func removable(_ item: Item) -> Profile? {
        guard case .member(let member) = item, isMember, member.id != store.userID else { return nil }
        return member
    }

    private func row(for member: Profile) -> ListRow {
        let stats = store.partyAverageScore(partyID: party.id, for: .account(member.id), limit: .max)
        let rated = stats.map { "\($0.count) rated here" }
        let you = member.id == store.userID ? "You" : nil
        return ListRow(
            member.firstName.isEmpty ? member.shownName : member.firstName,
            meta: [you, rated].compactMap { $0 }.joined(separator: " \u{00B7} "),
            leading: .avatar(Avatar(profile: member, size: .sm, decorative: true)),
            trailing: stats.map { .score($0.score) },
            chevron: true,
            action: { selectedMember = MemberSheetTarget(id: member.id) }
        )
    }
}
