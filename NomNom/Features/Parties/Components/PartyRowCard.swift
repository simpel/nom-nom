import SwiftUI

/// Minimal row representing a dinner party in lists and discovery.
struct PartyRowCard: View {
    let party: Party

    @Environment(FoodStore.self) private var store

    private var memberCount: Int {
        store.members(of: party.id).count
    }

    private var followerCount: Int {
        store.followers(of: party.id).count
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            PartyAvatar(party: party, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(party.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(1)
                }

                if !party.about.isEmpty {
                    Text(party.about)
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                        .monospacedDigit()

                    if followerCount > 0 {
                        Text("•")
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("\(followerCount) \(followerCount == 1 ? "follower" : "followers")")
                            .monospacedDigit()
                    }
                }
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyRowCard(party: party)
                .padding()
        }
    }
}
