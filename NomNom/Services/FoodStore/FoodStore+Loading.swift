import Foundation
import Supabase

extension FoodStore {

    func loadIfNeeded() async {
        guard !hasLoaded, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let dishes: [Dish] = supabase.from("dishes").select().execute().value
            async let meals: [Meal] = supabase.from("meals").select().execute().value
            async let eaters: [Eater] = supabase.from("eaters").select().execute().value
            async let ratings: [MealRating] = supabase.from("meal_ratings").select().execute().value
            async let invites: [MealInvite] = supabase.from("meal_invites").select().execute().value
            async let inbox: [AppNotification] = supabase.from("notifications").select().execute().value
            async let parties: [Party] = supabase.from("parties").select().execute().value
            async let partyMembers: [PartyMember] = supabase.from("party_members").select().execute().value
            async let partyInvites: [PartyInvite] = supabase.from("party_invites").select().execute().value
            async let partyFollowers: [PartyFollower] = supabase.from("party_followers").select().execute().value
            async let mealParties: [MealParty] = supabase.from("meal_parties").select().execute().value
            async let recipeFavorites: [RecipeFavorite] = supabase.from("recipe_favorites").select().execute().value

            self.dishes = try await dishes
            self.meals = try await meals
            self.eaters = try await eaters
            self.ratings = try await ratings
            self.invites = try await invites
            self.notifications = try await inbox
            self.parties = try await parties
            self.partyMembers = try await partyMembers
            self.partyInvites = try await partyInvites
            self.partyFollowers = try await partyFollowers
            self.mealParties = try await mealParties
            self.recipeFavorites = try await recipeFavorites

            reindex()
            try await loadProfiles()
            errorMessage = nil
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func loadProfiles() async throws {
        var wanted: Set<UUID> = [userID]
        wanted.formUnion(meals.map(\.createdBy))
        wanted.formUnion(dishes.map(\.ownerID))
        wanted.formUnion(invites.map(\.inviterID))
        wanted.formUnion(invites.compactMap(\.inviteeID))
        wanted.formUnion(ratings.compactMap(\.raterID))
        wanted.formUnion(partyMembers.map(\.userID))
        wanted.formUnion(partyInvites.map(\.inviterID))
        wanted.formUnion(partyInvites.compactMap(\.inviteeID))
        wanted.formUnion(parties.map(\.createdBy))
        wanted.formUnion(partyFollowers.map(\.userID))

        let missing = wanted.subtracting(profiles.keys)
        guard !missing.isEmpty else { return }

        let fetched: [Profile] = try await supabase
            .from("profiles")
            .select()
            .in("id", values: missing.map(\.uuidString))
            .execute()
            .value

        for profile in fetched { profiles[profile.id] = profile }
    }

    func reindex() {
        meals.sort { lhs, rhs in
            if lhs.eatenOn != rhs.eatenOn { return lhs.eatenOn > rhs.eatenOn }
            return lhs.createdAt > rhs.createdAt
        }
        eaters.sort { $0.sortIndex < $1.sortIndex }
        notifications.sort { $0.createdAt > $1.createdAt }
        parties.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        dishByID = Dictionary(dishes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        eaterByID = Dictionary(eaters.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        mealByID = Dictionary(meals.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        partyByID = Dictionary(parties.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        mealsByDish = Dictionary(grouping: meals, by: \.dishID)
        ratingsByMeal = Dictionary(grouping: ratings, by: \.mealID)
        invitesByMeal = Dictionary(grouping: invites, by: \.mealID)
        mealPartiesByMeal = Dictionary(grouping: mealParties, by: \.mealID)
        mealPartiesByParty = Dictionary(grouping: mealParties, by: \.partyID)
        partyMembersByParty = Dictionary(grouping: partyMembers, by: \.partyID)
        partyFollowersByParty = Dictionary(grouping: partyFollowers, by: \.partyID)
        favoriteRecipeIDs = Set(recipeFavorites.filter { $0.userID == userID }.map(\.recipeID))

        let myPartyIDs = self.myPartyIDs
        if let current = currentParty, !myPartyIDs.contains(current.id) {
            currentParty = nil
        } else if currentParty == nil,
                  let savedIDString = UserDefaults.standard.string(forKey: "selectedParty_\(userID.uuidString)"),
                  let savedID = UUID(uuidString: savedIDString),
                  myPartyIDs.contains(savedID),
                  let savedParty = partyByID[savedID] {
            currentParty = savedParty
        }
    }
}
