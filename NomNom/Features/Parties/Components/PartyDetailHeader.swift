import SwiftUI

/// Editorial hero header for a dinner party: large centered title,
/// centered metadata, about description, and follow toggle for non-members.
struct PartyDetailHeader: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var members: [Profile] {
        store.members(of: party.id)
    }

    private var followers: [PartyFollower] {
        store.followers(of: party.id)
    }

    private var isMember: Bool {
        store.isMember(of: party.id)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            PartyAvatar(party: party, size: 76)
                .padding(.bottom, 2)

            // Large centered hero title
            Text(party.name)
                .font(AppTypography.pageTitleFont)
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)

            // Centered metadata row
            HStack(spacing: 6) {
                Text("\(members.count) \(members.count == 1 ? "member" : "members")")
                    .monospacedDigit()

                if followers.count > 0 {
                    Text("•")
                        .foregroundStyle(DS.Color.textTertiary)

                    Text("\(followers.count) \(followers.count == 1 ? "follower" : "followers")")
                        .monospacedDigit()
                }

                if !party.isPublic {
                    Text("•")
                        .foregroundStyle(DS.Color.textTertiary)

                    Text("Private")
                }
            }
            .font(.inter(.subheadline))
            .foregroundStyle(DS.Color.textSecondary)

            // Centered about narrative
            if !party.about.isEmpty {
                Text(party.about)
                    .font(.inter(.body))
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyDetailHeader(party: party)
                .padding()
        }
    }
}
