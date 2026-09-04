import SwiftUI

/// Comprehensive, appetizing card representing a dinner party in My Parties, Following, and Discover.
///
/// Features:
/// - Party identity with monogram avatar, follower/member count, and host attribution
/// - Refined score pill badge in metadata row
/// - Party description strictly capped at 2 lines
/// - Horizontally scrollable list of meals with clean photo cards and names
/// - Total meals logged footer
/// - Interactive top-right follow icon button (when applicable)
struct PartyCard: View {
    let party: Party
    var showFollowButton: Bool? = nil

    @Environment(FoodStore.self) private var store

    private var isMember: Bool { store.isMember(of: party.id) }
    private var memberCount: Int { store.members(of: party.id).count }
    private var followerCount: Int { store.followers(of: party.id).count }
    private var partyMeals: [Meal] { store.meals(forParty: party.id) }
    private var hostName: String? { store.profiles[party.createdBy]?.shortName }
    private var scoreStats: FoodStore.PartyScoreStats? { store.partyAverageScore(partyID: party.id) }

    private var shouldShowFollowButton: Bool {
        showFollowButton ?? (!isMember && party.isPublic)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                PartyDetailView(partyID: party.id)
            } label: {
                cardBody
            }
            .buttonStyle(.plain)

            if shouldShowFollowButton {
                PartyFollowIconButton(party: party)
                    .padding(8)
            }
        }
    }

    // MARK: - Card Body

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if !party.about.isEmpty {
                Text(party.about)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(2.5)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !partyMeals.isEmpty {
                mealsHorizontalScroll
            }

            footerRow
        }
        .padding(14)
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
            PartyAvatar(party: party, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(party.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                HStack(alignment: .center, spacing: 6) {
                    if let stats = scoreStats {
                        PartyScoreBadge(stats: stats)
                    }

                    if isMember {
                        Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                            .monospacedDigit()
                    } else {
                        Text("\(followerCount) \(followerCount == 1 ? "follower" : "followers")")
                            .monospacedDigit()

                        if let hostName {
                            Text("•")
                                .foregroundStyle(DS.Color.textTertiary)
                            Text("Hosted by \(hostName)")
                                .lineLimit(1)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer(minLength: shouldShowFollowButton ? 36 : 0)
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
        }
    }

    private func mealItemCard(meal: Meal) -> some View {
        let recipe = store.dish(meal.dishID)
        return VStack(alignment: .leading, spacing: 6) {
            RecipeImageView(
                recipe: recipe,
                photoPath: meal.photoPath,
                cuisine: recipe?.cuisine,
                cornerRadius: AppRadius.photo
            )
            .frame(width: 140, height: 105)

            Text(store.dishName(forMeal: meal))
                .font(.caption.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 6) {
            if partyMeals.isEmpty {
                Text("New dinner party • No meals logged yet")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            } else {
                Text("\(partyMeals.count) \(partyMeals.count == 1 ? "meal" : "meals") logged")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                    .monospacedDigit()
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DS.Color.textTertiary)
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyCard(party: party)
                .padding()
        }
    }
}
