import SwiftUI

/// Displays the members of a dinner party ("Who's in there") with their rate scores
/// and navigation to their individual profiles.
struct PartyMembersSection: View {
    let party: Party

    @Environment(FoodStore.self) private var store

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
            }
        }
    }

    private func memberRow(for member: Profile) -> some View {
        let stats = store.partyAverageScore(partyID: party.id, for: .account(member.id), limit: 20)

        return HStack(spacing: 12) {
            // Monogram avatar (strictly no emoji)
            ZStack {
                Circle()
                    .fill(DS.Color.accentSoft)
                    .frame(width: 32, height: 32)
                Text(member.shownName.prefix(1).uppercased())
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DS.Color.accentText)
            }

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
                HStack(spacing: 6) {
                    let percent = Int((stats.score * 100).rounded())
                    Text("\(percent)%")
                        .font(Font.newsreader(.subheadline, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(stats.reaction.text)

                    Text(stats.reaction.shortLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(stats.reaction.text)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(stats.reaction.fill.opacity(0.14)))
                        .overlay(
                            Capsule().strokeBorder(stats.reaction.fill.opacity(0.28), lineWidth: 0.5)
                        )
                }
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
