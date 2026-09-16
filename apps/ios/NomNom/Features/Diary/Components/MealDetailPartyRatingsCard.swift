import SwiftUI

/// Card displaying individual dinner party member ratings (strictly no icons).
struct MealDetailPartyRatingsCard: View {
    let meal: Meal

    @Environment(FoodStore.self) private var store
    @State private var invitingMemberID: UUID?
    @State private var showRatingSheet = false
    @State private var askError: String?
    @State private var explanationTarget: ExplanationTarget?

    private struct ExplanationTarget: Identifiable {
        let id = UUID()
        let raterName: String
        let affinities: [RaterTagAffinity]
    }

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
            VStack(spacing: 0) {
                ForEach(partyMembers) { member in
                    let isMe = member.id == store.userID
                    let rating = store.rating(for: .account(member.id), on: meal.id)
                    let isAsked = mealInvites.contains { $0.inviteeID == member.id }
                    let affinities = store.raterExplanation(for: .account(member.id), meal: meal)

                    MealDetailMemberRatingRow(
                        name: member.shownName,
                        avatar: member.avatarEmoji,
                        photoPath: member.photoPath,
                        initialLetter: String(member.shownName.prefix(1)),
                        isMe: isMe,
                        rating: rating,
                        isAsked: isAsked,
                        isInviting: invitingMemberID == member.id,
                        hasExplanation: !affinities.isEmpty,
                        onTapRate: { showRatingSheet = true },
                        onAskToRate: { askToRate(member) },
                        onTapExplain: { explain(name: member.shownName, affinities: affinities) }
                    )
                }

                // Household Eaters Rows (Strictly NO ICONS)
                ForEach(householdEaterVerdicts) { verdict in
                    let affinities = store.raterExplanation(for: verdict.ref, meal: meal)

                    MealDetailMemberRatingRow(
                        name: verdict.name,
                        avatar: verdict.emoji,
                        initialLetter: String(verdict.name.prefix(1)),
                        isMe: false,
                        reaction: verdict.reaction,
                        isAsked: false,
                        isInviting: false,
                        hasExplanation: !affinities.isEmpty,
                        onTapExplain: { explain(name: verdict.name, affinities: affinities) }
                    )
                }
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            MealRatingSheet(mealID: meal.id)
        }
        .sheet(item: $explanationTarget) { target in
            MealRaterExplanationSheet(raterName: target.raterName, affinities: target.affinities)
        }
        .alert("Couldn't Send", isPresented: Binding(
            get: { askError != nil },
            set: { if !$0 { askError = nil } }
        )) {
            Button("OK") { askError = nil }
        } message: {
            Text(askError ?? "")
        }
    }

    private func explain(name: String, affinities: [RaterTagAffinity]) {
        guard !affinities.isEmpty else { return }
        explanationTarget = ExplanationTarget(raterName: name, affinities: affinities)
    }

    private func askToRate(_ member: Profile) {
        invitingMemberID = member.id
        Task {
            let ok = await store.askToRate(member: member, forMeal: meal.id)
            invitingMemberID = nil
            if !ok {
                askError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}
