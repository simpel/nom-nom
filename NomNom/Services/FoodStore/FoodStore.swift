import Foundation
import Observation
import OSLog

/// Everything the app knows, read from and written back to Postgres.
@MainActor
@Observable
final class FoodStore {

    let userID: UUID

    var dishes: [Recipe] = []
    var recipes: [Recipe] {
        get { dishes }
        set { dishes = newValue }
    }
    var meals: [Meal] = []
    var eaters: [Eater] = []
    var ratings: [MealRating] = []
    var invites: [MealInvite] = []
    var notifications: [AppNotification] = []
    var profiles: [UUID: Profile] = [:]

    // Dinner Parties
    var parties: [Party] = []
    var partyMembers: [PartyMember] = []
    var partyInvites: [PartyInvite] = []
    var partyFollowers: [PartyFollower] = []
    var mealParties: [MealParty] = []
    var recipeFavorites: [RecipeFavorite] = []
    var favoriteRecipeIDs: Set<UUID> = []
    var favoriteRecipes: [Recipe] {
        recipes.filter { favoriteRecipeIDs.contains($0.id) }
    }
    var currentParty: Party? {
        didSet {
            let key = "selectedParty_\(userID.uuidString)"
            if let id = currentParty?.id {
                UserDefaults.standard.set(id.uuidString, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    var isLoading = false
    var hasLoaded = false
    var errorMessage: String?

    // Lookups
    var mealsByDish: [UUID: [Meal]] = [:]
    var ratingsByMeal: [UUID: [MealRating]] = [:]
    var invitesByMeal: [UUID: [MealInvite]] = [:]
    var mealPartiesByMeal: [UUID: [MealParty]] = [:]
    var mealPartiesByParty: [UUID: [MealParty]] = [:]
    var partyMembersByParty: [UUID: [PartyMember]] = [:]
    var partyFollowersByParty: [UUID: [PartyFollower]] = [:]
    var dishByID: [UUID: Recipe] = [:]
    var recipeByID: [UUID: Recipe] { dishByID }
    var eaterByID: [UUID: Eater] = [:]
    var mealByID: [UUID: Meal] = [:]
    var partyByID: [UUID: Party] = [:]

    static let log = Logger(subsystem: "NomNom", category: "store")

    init(userID: UUID) {
        self.userID = userID
    }

    // MARK: - Slices the views want

    var myDishes: [Recipe] { dishes.filter { $0.ownerID == userID } }
    var myRecipes: [Recipe] { myDishes }

    func isFavorite(recipeID: UUID) -> Bool {
        favoriteRecipeIDs.contains(recipeID)
    }

    func isFavorite(recipe: Recipe) -> Bool {
        favoriteRecipeIDs.contains(recipe.id)
    }

    var myMeals: [Meal] { meals.filter { $0.createdBy == userID } }

    /// Context-filtered meals: if a party is selected, returns all meals served to that party;
    /// otherwise returns your personal diary meals ("Just me").
    var activeMeals: [Meal] {
        if let party = currentParty {
            let mealIDs = Set((mealPartiesByParty[party.id] ?? []).map(\.mealID))
            return meals.filter { mealIDs.contains($0.id) }
        }
        return myMeals
    }

    var myParties: [Party] {
        let myPartyIDs = Set(partyMembers.filter { $0.userID == userID }.map(\.partyID))
        return parties.filter { myPartyIDs.contains($0.id) }
    }

    var followedPartyIDs: Set<UUID> {
        Set(partyFollowers.filter { $0.userID == userID }.map(\.partyID))
    }

    var followedParties: [Party] {
        let ids = followedPartyIDs
        return parties.filter { ids.contains($0.id) }
    }

    var publicParties: [Party] {
        parties.filter(\.isPublic)
    }

    var discoverParties: [Party] {
        let myIDs = Set(partyMembers.filter { $0.userID == userID }.map(\.partyID))
        let followedIDs = followedPartyIDs
        return parties.filter { $0.isPublic && !myIDs.contains($0.id) && !followedIDs.contains($0.id) }
    }

    func isFollowing(partyID: UUID) -> Bool {
        followedPartyIDs.contains(partyID)
    }

    func isMember(of partyID: UUID) -> Bool {
        partyMembers.contains { $0.partyID == partyID && $0.userID == userID }
    }

    func followers(of partyID: UUID) -> [PartyFollower] {
        partyFollowersByParty[partyID] ?? []
    }

    func searchParties(matching query: String) -> [Party] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return parties }
        return parties.filter { party in
            party.name.lowercased().contains(trimmed) ||
            party.about.lowercased().contains(trimmed)
        }
    }

    var pendingPartyInvites: [PartyInvite] {
        partyInvites.filter { $0.inviteeID == userID && $0.status == .pending }
    }

    var activeEaters: [Eater] { eaters.filter { $0.ownerID == userID && $0.isActive } }

    var myEaters: [Eater] { eaters.filter { $0.ownerID == userID && $0.isActive } }

    var myProfile: Profile? { profiles[userID] }

    var isProfileSetup: Bool {
        guard let p = myProfile else { return false }
        return !p.firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var unreadCount: Int { notifications.filter(\.isUnread).count }

    var invitedMeals: [Meal] {
        let mine = Set(invites.filter { $0.inviteeID == userID }.map(\.mealID))
        return meals.filter { mine.contains($0.id) && $0.createdBy != userID }
    }

    var awaitingMyRating: [Meal] {
        invitedMeals.filter { meal in
            !(ratingsByMeal[meal.id] ?? []).contains { $0.raterID == userID }
        }
    }

    func dish(_ id: UUID) -> Recipe? { dishByID[id] }
    func recipe(_ id: UUID) -> Recipe? { dishByID[id] }
    func eater(_ id: UUID) -> Eater? { eaterByID[id] }
    func meal(_ id: UUID) -> Meal? { mealByID[id] }
    func party(_ id: UUID) -> Party? { partyByID[id] }

    func dishName(forMeal meal: Meal) -> String {
        dishByID[meal.dishID]?.name ?? "Untitled"
    }

    func recipeName(forMeal meal: Meal) -> String {
        dishByID[meal.recipeID]?.name ?? "Untitled"
    }

    func servings(of dishID: UUID) -> [Meal] {
        mealsByDish[dishID] ?? []
    }

    func ratings(forMeal mealID: UUID) -> [MealRating] {
        ratingsByMeal[mealID] ?? []
    }

    func invites(forMeal mealID: UUID) -> [MealInvite] {
        invitesByMeal[mealID] ?? []
    }

    func parties(forMeal mealID: UUID) -> [Party] {
        let pIDs = (mealPartiesByMeal[mealID] ?? []).map(\.partyID)
        return pIDs.compactMap { partyByID[$0] }
    }

    func meals(forParty partyID: UUID) -> [Meal] {
        let mealIDs = Set((mealPartiesByParty[partyID] ?? []).map(\.mealID))
        return meals.filter { mealIDs.contains($0.id) }
    }

    func members(of partyID: UUID) -> [Profile] {
        let uIDs = (partyMembersByParty[partyID] ?? []).map(\.userID)
        return uIDs.compactMap { profiles[$0] }
    }

    func invites(forParty partyID: UUID) -> [PartyInvite] {
        partyInvites.filter { $0.partyID == partyID }
    }

    func averageScore(forMeal mealID: UUID) -> Double? {
        let scores = ratings(forMeal: mealID).map(\.reaction.score)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    struct VerdictDetail: Identifiable {
        let ref: RaterRef
        let emoji: String
        let name: String
        let reaction: Reaction?

        var id: String {
            switch ref {
            case .eater(let id): return "eater_\(id.uuidString)"
            case .account(let id): return "account_\(id.uuidString)"
            }
        }
    }

    func verdictDetails(forMeal mealID: UUID) -> [VerdictDetail] {
        let sorted = ratings(forMeal: mealID).sorted { lhs, rhs in
            switch (lhs.source, rhs.source) {
            case (.eater(let l), .eater(let r)):
                return (eaterByID[l]?.sortIndex ?? 0) < (eaterByID[r]?.sortIndex ?? 0)
            case (.eater, .account):
                return true
            case (.account, .eater):
                return false
            case (.account(let l), .account(let r)):
                if l == userID { return true }
                if r == userID { return false }
                return (profiles[l]?.shownName ?? "") < (profiles[r]?.shownName ?? "")
            }
        }
        return sorted.map { rating in
            let who = label(for: rating.source)
            return VerdictDetail(ref: rating.source, emoji: who.emoji, name: who.name, reaction: rating.reaction)
        }
    }

    func verdictEntries(forMeal mealID: UUID) -> [(emoji: String, name: String, reaction: Reaction?)] {
        verdictDetails(forMeal: mealID).map { (emoji: $0.emoji, name: $0.name, reaction: $0.reaction) }
    }

    var dishHistory: [UUID: DishHistory] {
        var history: [UUID: DishHistory] = [:]
        for dish in myDishes {
            let servings = mealsByDish[dish.id] ?? []
            history[dish.id] = DishHistory(timesServed: servings.count,
                                          lastServed: servings.map(\.eatenOn).max())
        }
        return history
    }

    var suggestionInputs: SuggestionEngine.Inputs {
        SuggestionEngine.Inputs(dishes: myDishes,
                                mealsByDish: mealsByDish,
                                ratingsByMeal: ratingsByMeal,
                                roster: raterRoster)
    }

    func label(for ref: RaterRef) -> (emoji: String, name: String) {
        switch ref {
        case .eater(let id):
            guard let eater = eaterByID[id] else { return ("🍽️", "Someone") }
            return (eater.emoji, eater.name)
        case .account(let id):
            guard let profile = profiles[id] else {
                return ("🧑", id == userID ? "Me" : "Someone")
            }
            return (profile.avatarEmoji, id == userID ? "Me" : profile.shownName)
        }
    }

    var raterRoster: [(ref: RaterRef, emoji: String, name: String)] {
        var roster = activeEaters.map { (ref: $0.raterRef, emoji: $0.emoji, name: $0.name) }
        let me = label(for: .account(userID))
        roster.append((ref: .account(userID), emoji: me.emoji, name: me.name))
        return roster
    }

    // MARK: - Local patching

    func upsertLocal(recipe: Recipe) {
        if let index = dishes.firstIndex(where: { $0.id == recipe.id }) {
            dishes[index] = recipe
        } else {
            dishes.append(recipe)
        }
        dishByID[recipe.id] = recipe
    }

    func upsertLocal(dish: Recipe) {
        upsertLocal(recipe: dish)
    }

    func upsertLocal(meal: Meal) {
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
        } else {
            meals.append(meal)
        }
        mealByID[meal.id] = meal
    }

    func upsertLocal(rating: MealRating) {
        if let index = ratings.firstIndex(where: { $0.id == rating.id }) {
            ratings[index] = rating
        } else {
            ratings.append(rating)
        }
    }
}
