import Foundation

extension FoodStore {

    static let previewUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let friendUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// A pre-populated store with realistic data for Canvas SwiftUI #Previews.
    static var preview: FoodStore {
        let store = FoodStore(userID: previewUserID)
        store.hasLoaded = true

        // Profiles
        let myProfile = Profile(
            id: previewUserID,
            firstName: "Joel",
            lastName: "Sandén",
            displayName: "Joel",
            avatarEmoji: "🧑‍🍳"
        )
        let friendProfile = Profile(
            id: friendUserID,
            firstName: "Alice",
            lastName: "Lind",
            displayName: "Alice",
            avatarEmoji: "👩‍🌾"
        )
        store.profiles = [
            previewUserID: myProfile,
            friendUserID: friendProfile
        ]

        // Eaters (household members)
        let kid1 = Eater(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            ownerID: previewUserID,
            name: "Leo",
            emoji: "👦",
            sortIndex: 0
        )
        let kid2 = Eater(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            ownerID: previewUserID,
            name: "Maya",
            emoji: "👧",
            sortIndex: 1
        )
        store.eaters = [kid1, kid2]

        // Party
        let partyID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
        let party = Party(
            id: partyID,
            name: "Dinner Club",
            createdBy: previewUserID
        )
        store.parties = [party]
        store.partyMembers = [
            PartyMember(partyID: partyID, userID: previewUserID),
            PartyMember(partyID: partyID, userID: friendUserID)
        ]

        // Recipes / Dishes
        let recipe1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let recipe2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let recipe3ID = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!

        let tacos = Recipe(
            id: recipe1ID,
            ownerID: previewUserID,
            name: "Birria Tacos",
            tags: ["mexican", "comfort", "dinner"],
            recipeText: "1. Slow cook beef with guajillo chilies, onions, garlic and spices for 3 hours.\n2. Dip corn tortillas in consommé and fry on flat top.\n3. Fill with shredded beef, Oaxaca cheese, cilantro and diced onion.",
            effort: .over60
        )
        let salmon = Recipe(
            id: recipe2ID,
            ownerID: previewUserID,
            name: "Crispy Salmon Bowl",
            tags: ["quick", "fish", "healthy"],
            recipeText: "Pan sear salmon fillets skin-side down for 4 mins. Serve over warm sushi rice with edamame, avocado, cucumber, and spicy mayo.",
            effort: .fifteenTo30
        )
        let pasta = Recipe(
            id: recipe3ID,
            ownerID: previewUserID,
            name: "Cacio e Pepe",
            tags: ["pasta", "italian", "classic"],
            recipeText: "Toast freshly cracked black pepper in olive oil. Emulsify pasta water with Pecorino Romano cheese until velvety smooth.",
            effort: .zeroTo15
        )
        store.dishes = [tacos, salmon, pasta]

        // Meals
        let meal1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let meal2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!

        let meal1 = Meal(
            id: meal1ID,
            recipeID: recipe1ID,
            createdBy: previewUserID,
            eatenOn: .now,
            notes: "Made extra crispy with homemade salsa verde! Huge hit with the family.",
            effort: .over60,
            repeatDesire: .staple
        )
        let meal2 = Meal(
            id: meal2ID,
            recipeID: recipe2ID,
            createdBy: previewUserID,
            eatenOn: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
            notes: "Quick weeknight dinner after swim practice.",
            effort: .fifteenTo30,
            repeatDesire: .sometimes
        )
        store.meals = [meal1, meal2]

        // Ratings / Verdicts
        let rating1 = MealRating(mealID: meal1ID, raterID: previewUserID, reaction: .amazing)
        let rating2 = MealRating(mealID: meal1ID, eaterID: kid1.id, reaction: .amazing)
        let rating3 = MealRating(mealID: meal1ID, eaterID: kid2.id, reaction: .good)
        let rating4 = MealRating(mealID: meal2ID, raterID: previewUserID, reaction: .amazing)
        store.ratings = [rating1, rating2, rating3, rating4]

        // Meal parties
        store.mealParties = [
            MealParty(mealID: meal1ID, partyID: partyID)
        ]

        store.reindex()
        return store
    }

    /// An empty store for testing zero-data / empty states.
    static var empty: FoodStore {
        let store = FoodStore(userID: previewUserID)
        store.hasLoaded = true
        store.profiles = [
            previewUserID: Profile(id: previewUserID, firstName: "Joel", displayName: "Joel")
        ]
        store.reindex()
        return store
    }
}
