import SwiftUI

/// Combined dinner party memberships and average scores list showing name, scores, and navigation arrow.
struct ProfilePartiesSection: View {
    let parties: [Party]
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store

    var body: some View {
        SectionCard("Dinner Parties (\(parties.count))") {
            if parties.isEmpty {
                Text("No dinner party memberships.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(parties.enumerated()), id: \.element.id) { index, party in
                        let stats = store.partyAverageScore(partyID: party.id, for: raterRef, limit: 20)

                        NavigationLink {
                            PartyDetailView(partyID: party.id)
                        } label: {
                            HStack(spacing: 12) {
                                PartyAvatar(party: party, size: 36)

                                Text(party.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                if let stats {
                                    ScoreBadge(stats: stats, format: .both, size: .sm)
                                } else {
                                    Text("—")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DS.Color.textTertiary)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < parties.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        ProfilePartiesSection(
            parties: store.parties,
            raterRef: .account(store.userID)
        )
        .padding()
    }
}
