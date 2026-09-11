import SwiftUI

/// Appetizing card representing a dinner party in Following and Discover lists.
///
/// Features:
/// - Party identity with avatar, name, subtitle member names/host, and far-right follow button
/// - Party description capped at 2 lines
/// - Reuses DividedScoreCard for average rating and meal count
/// - Horizontally scrollable list of meals with dish photo cards
struct PartyCard: View {
    let party: Party
    var showFollowButton: Bool? = nil

    @Environment(FoodStore.self) private var store
    @State private var showingInviteSheet = false

    private var isMember: Bool { store.isMember(of: party.id) }
    private var members: [Profile] { store.members(of: party.id) }
    private var partyMeals: [Meal] { store.meals(forParty: party.id) }
    private var hostName: String? { store.profiles[party.createdBy]?.shortName }
    private var scoreStats: FoodStore.PartyScoreStats? { store.partyAverageScore(partyID: party.id) }

    private var shouldShowFollowButton: Bool {
        guard !isMember && party.isPublic else { return false }
        return showFollowButton ?? true
    }

    private var subtitleText: String {
        if !members.isEmpty {
            return members.map(\.shortName).joined(separator: ", ")
        } else if let hostName {
            return "Hosted by \(hostName)"
        }
        return ""
    }

    var body: some View {
        NavigationLink {
            PartyDetailView(partyID: party.id)
        } label: {
            cardBody
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isMember {
                Button {
                    showingInviteSheet = true
                } label: {
                    Label("Invite Member", systemImage: "person.badge.plus")
                }

                ShareLink(
                    item: party.inviteURL,
                    subject: Text("Join \(party.name) on Nom Nom"),
                    message: Text(party.shareMessage)
                ) {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            PartyInviteView(party: party)
        }
    }

    // MARK: - Card Body

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow

            if !party.about.isEmpty {
                Text(party.about)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(2)
            }

            scoreSection

            if !partyMeals.isEmpty {
                mealsHorizontalScroll
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.panel)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            PartyAvatar(party: party, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(party.name)
                    .font(AppTypography.displayL)
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                if !subtitleText.isEmpty {
                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if shouldShowFollowButton {
                PartyFollowIconButton(party: party)
            }
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
                    mealCount: partyMeals.count
                )
            } else {
                DividedScoreCard(
                    score: "—",
                    verdict: "Unrated",
                    color: DS.Color.textTertiary,
                    mealCount: partyMeals.count
                )
            }
        }
    }

    // MARK: - Meals Horizontal Scroll

    private var mealsHorizontalScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(partyMeals) { meal in
                    mealItemCard(meal: meal)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
        }
        .padding(.horizontal, -DS.Spacing.md)
    }

    private func mealItemCard(meal: Meal) -> some View {
        let recipe = store.dish(meal.dishID)
        let mealReaction = store.averageReaction(forMeal: meal.id)

        return VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RecipeImageView(
                    recipe: recipe,
                    photoPath: meal.photoPath,
                    cuisine: recipe?.cuisine,
                    cornerRadius: AppRadius.photo
                )
                .frame(width: 148, height: 102)

                if let reaction = mealReaction {
                    Text(reaction.shortLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(reaction.text)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(DS.Color.panel.opacity(0.92)))
                        .overlay(
                            Capsule()
                                .strokeBorder(reaction.fill.opacity(0.35), lineWidth: 0.5)
                        )
                        .padding(6)
                }
            }

            Text(store.dishName(forMeal: meal))
                .font(.caption.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 148, height: 32, alignment: .topLeading)
        }
    }
}

#Preview("Discover Party") {
    NomNomPreview { store in
        if let party = store.parties.first(where: { $0.isPublic && !store.isMember(of: $0.id) }) ?? store.parties.first {
            PartyCard(party: party)
                .padding()
        }
    }
}

#Preview("Member Party") {
    NomNomPreview { store in
        if let party = store.parties.first(where: { store.isMember(of: $0.id) }) {
            PartyCard(party: party)
                .padding()
        }
    }
}
