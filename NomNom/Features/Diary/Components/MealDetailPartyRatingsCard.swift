import SwiftUI

/// Card displaying dinner party members, their ratings for this meal, and quick "Ask to rate" actions.
struct MealDetailPartyRatingsCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var invitingMemberID: UUID?
    @State private var showRatingSheet = false

    private var parties: [Party] {
        let mealParties = store.parties(forMeal: meal.id)
        if !mealParties.isEmpty { return mealParties }
        return store.currentParty.map { [$0] } ?? store.parties
    }

    private var partyMembers: [Profile] {
        var seen = Set<UUID>()
        var list: [Profile] = []

        // Always include current user first
        let myProfile = store.myProfile ?? Profile(id: store.userID, displayName: "You", avatarEmoji: "🧑")
        list.append(myProfile)
        seen.insert(store.userID)

        for party in parties {
            for member in store.members(of: party.id) {
                if !seen.contains(member.id) {
                    seen.insert(member.id)
                    list.append(member)
                }
            }
        }
        return list
    }

    private var mealInvites: [MealInvite] {
        store.invites(forMeal: meal.id)
    }

    var body: some View {
        SectionCard(title: "Ratings") {
            VStack(spacing: 12) {
                ForEach(partyMembers) { member in
                    memberRow(member)
                }

                // Household eaters ratings if any
                ForEach(householdEaterVerdicts) { verdict in
                    eaterRow(verdict)
                }
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            MealRatingSheet(mealID: meal.id)
        }
    }

    // MARK: - Member Rows

    @ViewBuilder
    private func memberRow(_ member: Profile) -> some View {
        let isMe = member.id == store.userID
        let rating = store.rating(for: .account(member.id), on: meal.id)
        let isAsked = mealInvites.contains { $0.inviteeID == member.id }

        if isMe {
            myRatingRow(member: member, rating: rating)
        } else {
            otherMemberRow(member: member, rating: rating, isAsked: isAsked)
        }
    }

    @ViewBuilder
    private func myRatingRow(member: Profile, rating: MealRating?) -> some View {
        Button {
            showRatingSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Text(member.displayName.prefix(1).uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }

                Text("You")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                if let reaction = rating?.reaction {
                    HStack(spacing: 5) {
                        Image(systemName: reaction.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                        Text(reaction.shortLabel)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(reaction.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(reaction.tint.opacity(0.12)))
                } else {
                    Text("Rate")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func otherMemberRow(member: Profile, rating: MealRating?, isAsked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text(member.shownName.prefix(1).uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }

            Text(member.shownName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            if let reaction = rating?.reaction {
                HStack(spacing: 5) {
                    Image(systemName: reaction.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                    Text(reaction.shortLabel)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(reaction.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(reaction.tint.opacity(0.12)))
            } else if isAsked {
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.caption2)
                    Text("Asked")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.1), in: Capsule())
            } else {
                Button {
                    invitingMemberID = member.id
                    Task {
                        _ = await store.askToRate(member: member, forMeal: meal.id)
                        invitingMemberID = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        if invitingMemberID == member.id {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                        }
                        Text("Ask to rate")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(invitingMemberID != nil)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Household Eaters

    private var householdEaterVerdicts: [FoodStore.VerdictDetail] {
        store.verdictDetails(forMeal: meal.id).filter { detail in
            if case .eater = detail.ref { return true }
            return false
        }
    }

    @ViewBuilder
    private func eaterRow(_ detail: FoodStore.VerdictDetail) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text(detail.name.prefix(1).uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primary)
            }

            Text(detail.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            if let reaction = detail.reaction {
                HStack(spacing: 5) {
                    Image(systemName: reaction.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                    Text(reaction.shortLabel)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(reaction.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(reaction.tint.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }
}
