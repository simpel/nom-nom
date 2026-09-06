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
    @State private var showingInviteSheet = false

    private var isMember: Bool { store.isMember(of: party.id) }
    private var memberCount: Int { store.members(of: party.id).count }
    private var followerCount: Int { store.followers(of: party.id).count }
    private var partyMeals: [Meal] { store.meals(forParty: party.id) }
    private var hostName: String? { store.profiles[party.createdBy]?.shortName }
    private var scoreStats: FoodStore.PartyScoreStats? { store.partyAverageScore(partyID: party.id) }

    private var shouldShowFollowButton: Bool {
        guard !isMember && party.isPublic else { return false }
        return showFollowButton ?? true
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
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

            if shouldShowFollowButton {
                PartyFollowIconButton(party: party)
                    .padding(.top, scoreStats != nil ? 20 : 16)
                    .padding(.trailing, 10)
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
                    .lineSpacing(3)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !partyMeals.isEmpty {
                mealsHorizontalScroll
            }

            footerRow
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

            VStack(alignment: .leading, spacing: 5) {
                Text(party.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                if let stats = scoreStats {
                    ScoreBadge(stats: stats, format: .both, size: .sm)
                }
            }

            Spacer(minLength: 8)

            if shouldShowFollowButton {
                // Invisible reservation matching the 32x32 circle of the follow button overlay
                Color.clear
                    .frame(width: 32, height: 32)
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

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 6) {
            if partyMeals.isEmpty {
                Text("No meals logged yet")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            } else {
                Text("\(partyMeals.count) \(partyMeals.count == 1 ? "meal" : "meals") logged")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DS.Color.textSecondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                if let hostName {
                    Text("Hosted by \(hostName)")
                        .lineLimit(1)

                    Text("•")
                        .foregroundStyle(DS.Color.textTertiary)
                }

                if isMember {
                    Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                        .monospacedDigit()
                } else {
                    Text("\(followerCount) \(followerCount == 1 ? "follower" : "followers")")
                        .monospacedDigit()
                }
            }
            .font(.caption)
            .foregroundStyle(DS.Color.textSecondary)
            .lineLimit(1)
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
