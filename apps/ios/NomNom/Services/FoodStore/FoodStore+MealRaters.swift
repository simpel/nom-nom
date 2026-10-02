import Foundation

/// Who could rate a meal: the viewer, the meal's party members, anyone asked to
/// rate it, any other account that rated it, then household eaters with a verdict.
extension FoodStore {

    struct MealRater: Identifiable {
        let ref: RaterRef
        let name: String
        var photoPath: String?
        /// The account's profile, for asking them to rate. Nil for household eaters.
        var profile: Profile?
        var rating: MealRating?
        var isViewer: Bool
        /// They have a pending ask-to-rate invite for this meal.
        var isAsked: Bool

        var id: String {
            switch ref {
            case .eater(let id): return "eater_\(id.uuidString)"
            case .account(let id): return "account_\(id.uuidString)"
            }
        }
    }

    func raters(forMeal meal: Meal) -> [MealRater] {
        let invites = invites(forMeal: meal.id)
        var raters: [MealRater] = accountProfiles(forMeal: meal, invites: invites).map { profile in
            let ref = RaterRef.account(profile.id)
            return MealRater(
                ref: ref,
                name: profile.shownName,
                photoPath: profile.photoPath,
                profile: profile,
                rating: rating(for: ref, on: meal.id),
                isViewer: profile.id == userID,
                isAsked: invites.contains { $0.inviteeID == profile.id }
            )
        }
        for detail in verdictDetails(forMeal: meal.id) {
            guard case .eater = detail.ref else { continue }
            raters.append(MealRater(
                ref: detail.ref,
                name: detail.name,
                rating: rating(for: detail.ref, on: meal.id),
                isViewer: false,
                isAsked: false
            ))
        }
        return raters
    }

    private func accountProfiles(forMeal meal: Meal, invites: [MealInvite]) -> [Profile] {
        var seen: Set<UUID> = [userID]
        var list: [Profile] = [myProfile ?? Profile(id: userID, displayName: "You", avatarEmoji: "")]

        func add(_ id: UUID, fallbackName: String) {
            guard !seen.contains(id) else { return }
            seen.insert(id)
            list.append(profiles[id] ?? Profile(id: id, displayName: fallbackName, avatarEmoji: ""))
        }

        let mealParties = parties(forMeal: meal.id)
        let rosterParties = !mealParties.isEmpty ? mealParties : (currentParty.map { [$0] } ?? parties)
        for party in rosterParties {
            for member in members(of: party.id) { add(member.id, fallbackName: member.shownName) }
        }
        for invite in invites {
            if let inviteeID = invite.inviteeID { add(inviteeID, fallbackName: invite.inviteeEmail ?? "Guest") }
        }
        for rating in ratings(forMeal: meal.id) {
            if case .account(let accountID) = rating.source { add(accountID, fallbackName: "Guest") }
        }
        return list
    }
}
