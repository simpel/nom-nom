import SwiftUI

/// The member sheet's PersonHeaderRow: Avatar `lg`, the first name in `serif-md`, and
/// "Member since Mar 2026 · 18 meals rated here". Opens their profile.
struct PartyMemberHeaderRow: View {
    let memberRef: RaterRef
    let partyID: UUID
    let ratedCount: Int
    let onOpenProfile: () -> Void

    @Environment(FoodStore.self) private var store

    private var accountID: UUID? {
        if case .account(let id) = memberRef { return id }
        return nil
    }

    private var meta: String {
        var parts: [String] = []
        if let accountID,
           let joined = (store.partyMembersByParty[partyID] ?? []).first(where: { $0.userID == accountID })?.joinedAt {
            parts.append("Member since \(joined.formatted(.dateTime.month(.abbreviated).year()))")
        }
        parts.append(ratedCount == 1 ? "1 meal rated here" : "\(ratedCount) meals rated here")
        return parts.joined(separator: " \u{00B7} ")
    }

    private var avatar: Avatar {
        if let profile = accountID.flatMap({ store.profiles[$0] }) {
            return Avatar(profile: profile, size: .lg, decorative: true)
        }
        return Avatar(name: store.label(for: memberRef).name, size: .lg, decorative: true)
    }

    var body: some View {
        PersonHeaderRow(
            avatar: avatar,
            name: store.firstName(for: memberRef),
            meta: meta,
            nameStyle: .serifMd,
            action: accountID == nil ? nil : onOpenProfile
        )
    }
}
