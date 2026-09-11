import SwiftUI

/// Editorial hero view representing the current active dinner party:
/// - Party identity with avatar, name, and switch party icon button on the far right
/// - Member names displayed as clean text (no badges)
/// - Score component (DividedScoreCard) integrating average rating, verdict, and meal count
/// - Entire card is clickable to navigate into PartyDetailView
struct CurrentPartyHeroView: View {
    let party: Party?
    var onCreateParty: () -> Void

    @Environment(FoodStore.self) private var store

    private var members: [Profile] {
        guard let party else { return [] }
        return store.members(of: party.id)
    }

    private var scoreStats: FoodStore.PartyScoreStats? {
        guard let party else { return nil }
        return store.partyAverageScore(partyID: party.id)
    }

    private var mealsTogetherCount: Int {
        guard let party else { return 0 }
        return store.meals(forParty: party.id).count
    }

    private var memberNamesText: String {
        members.map(\.shortName).joined(separator: ", ")
    }

    var body: some View {
        if let party {
            NavigationLink {
                PartyDetailView(partyID: party.id)
            } label: {
                activePartyCard(party: party)
            }
            .buttonStyle(.plain)
        } else {
            emptyPartyCard
        }
    }

    // MARK: - Active Party Card

    private func activePartyCard(party: Party) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow(party: party)

            if !party.about.isEmpty {
                Text(party.about)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(2)
            }

            scoreSection
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
        )
    }

    // MARK: - Header & Switcher

    private func headerRow(party: Party) -> some View {
        HStack(alignment: .center, spacing: 12) {
            PartyAvatar(party: party, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(party.name)
                    .font(AppTypography.displayL)
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                if !memberNamesText.isEmpty {
                    Text(memberNamesText)
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            partySwitcherMenu(currentParty: party)
        }
    }

    private func partySwitcherMenu(currentParty: Party) -> some View {
        Menu {
            Section("Switch Dinner Party") {
                ForEach(store.myParties) { p in
                    Button {
                        store.currentParty = p
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        HStack {
                            Text(p.name)
                            if p.id == currentParty.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                onCreateParty()
            } label: {
                Label("New Dinner Party", systemImage: "plus")
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 32, height: 32)
                .background(DS.Color.bg.opacity(0.8))
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        Group {
            if let stats = scoreStats {
                DividedScoreCard(
                    score: String(format: "%.1f", stats.score * 100),
                    verdict: stats.reaction.shortLabel,
                    color: stats.reaction.text,
                    mealCount: mealsTogetherCount
                )
            } else {
                DividedScoreCard(
                    score: "—",
                    verdict: "Unrated",
                    color: DS.Color.textTertiary,
                    mealCount: mealsTogetherCount
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyPartyCard: some View {
        VStack(spacing: 14) {
            PartyAvatar(name: "Nom Nom", size: 56)

            VStack(spacing: 4) {
                Text("No Dinner Party Selected")
                    .font(AppTypography.displayM)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Create or join a dinner party to start logging meals and ratings together.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            AppButton(
                "Create a Party",
                systemImage: "plus",
                variant: .primary,
                style: .normal,
                size: .md,
                action: onCreateParty
            )
            .padding(.top, 4)
        }
        .padding(DS.Spacing.sectionCompact)
        .frame(maxWidth: .infinity)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
        )
    }
}
