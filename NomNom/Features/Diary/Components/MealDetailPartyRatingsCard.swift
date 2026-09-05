import SwiftUI

/// Card displaying individual dinner party member ratings (strictly no icons).
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

        let myProfile = store.myProfile ?? Profile(id: store.userID, displayName: "You", avatarEmoji: "")
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

        // Include any outside invited members or accounts that have rated this meal
        for invite in mealInvites {
            if let inviteeID = invite.inviteeID, !seen.contains(inviteeID) {
                seen.insert(inviteeID)
                let profile = store.profiles[inviteeID] ?? Profile(id: inviteeID, displayName: invite.inviteeEmail ?? "Guest", avatarEmoji: "")
                list.append(profile)
            }
        }
        for rating in store.ratings(forMeal: meal.id) {
            if case .account(let accountID) = rating.source, !seen.contains(accountID) {
                seen.insert(accountID)
                let profile = store.profiles[accountID] ?? Profile(id: accountID, displayName: "Guest", avatarEmoji: "")
                list.append(profile)
            }
        }

        return list
    }

    private var mealInvites: [MealInvite] {
        store.invites(forMeal: meal.id)
    }

    private var householdEaterVerdicts: [FoodStore.VerdictDetail] {
        store.verdictDetails(forMeal: meal.id).filter { detail in
            if case .eater = detail.ref { return true }
            return false
        }
    }

    private var totalParticipants: Int {
        partyMembers.count + householdEaterVerdicts.count
    }

    private var ratingsCaption: String {
        let ratings = store.ratings(forMeal: meal.id)
        guard !ratings.isEmpty else { return "Awaiting ratings" }
        if totalParticipants > 0 {
            return "\(ratings.count) of \(totalParticipants) rated"
        }
        return "\(ratings.count) rating\(ratings.count == 1 ? "" : "s")"
    }

    var body: some View {
        SectionCard("Participants", caption: ratingsCaption) {
            VStack(spacing: 12) {
                ForEach(partyMembers) { member in
                    let isMe = member.id == store.userID
                    let rating = store.rating(for: .account(member.id), on: meal.id)
                    let isAsked = mealInvites.contains { $0.inviteeID == member.id }

                    MealDetailMemberRatingRow(
                        name: member.shownName,
                        avatar: member.avatarEmoji,
                        photoPath: member.photoPath,
                        initialLetter: String(member.shownName.prefix(1)),
                        isMe: isMe,
                        rating: rating,
                        isAsked: isAsked,
                        isInviting: invitingMemberID == member.id,
                        onTapRate: { showRatingSheet = true },
                        onAskToRate: { askToRate(member) }
                    )
                }

                // Household Eaters Rows (Strictly NO ICONS)
                ForEach(householdEaterVerdicts) { verdict in
                    MealDetailMemberRatingRow(
                        name: verdict.name,
                        avatar: verdict.emoji,
                        initialLetter: String(verdict.name.prefix(1)),
                        isMe: false,
                        reaction: verdict.reaction,
                        isAsked: false,
                        isInviting: false
                    )
                }
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            MealRatingSheet(mealID: meal.id)
        }
    }

    private func askToRate(_ member: Profile) {
        invitingMemberID = member.id
        Task {
            _ = await store.askToRate(member: member, forMeal: meal.id)
            invitingMemberID = nil
        }
    }
}
