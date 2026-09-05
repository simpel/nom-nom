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

        // Parties
        let partyID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
        let party = Party(
            id: partyID,
            name: "Dinner Club",
            about: "A warm Friday evening dinner club sharing homemade comfort food and taco experiments.",
            isPublic: true,
            createdBy: previewUserID
        )

        let publicPartyID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
        let publicParty = Party(
            id: publicPartyID,
            name: "Nordic Cooks",
            about: "Exploring seasonal Scandinavian cuisine, slow braises, and traditional pastries.",
            isPublic: true,
            createdBy: friendUserID
        )

        let discoverPartyID = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!
        let discoverParty = Party(
            id: discoverPartyID,
            name: "Pasta Society",
            about: "Handmade semolina pasta, rich ragùs, and sourdough focaccia every weekend.",
            isPublic: true,
            createdBy: friendUserID
        )

        store.parties = [party, publicParty, discoverParty]
        store.partyMembers = [
            PartyMember(partyID: partyID, userID: previewUserID),
            PartyMember(partyID: partyID, userID: friendUserID),
            PartyMember(partyID: publicPartyID, userID: friendUserID),
            PartyMember(partyID: discoverPartyID, userID: friendUserID)
        ]
        store.partyFollowers = [
            PartyFollower(partyID: publicPartyID, userID: previewUserID)
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
            ingredients: [
                RecipeIngredient(quantity: "1", measurement: "kg", ingredient: "beef chuck"),
                RecipeIngredient(quantity: "4", measurement: "", ingredient: "guajillo chilies"),
                RecipeIngredient(quantity: "12", measurement: "", ingredient: "corn tortillas"),
                RecipeIngredient(quantity: "200", measurement: "g", ingredient: "Oaxaca cheese")
            ],
            instructions: [
                "Slow cook beef with guajillo chilies, onions, garlic and spices for 3 hours.",
                "Dip corn tortillas in consommé and fry on flat top.",
                "Fill with shredded beef, Oaxaca cheese, cilantro and diced onion."
            ],
            effort: .over60,
            cuisine: "mexican"
        )
        let salmon = Recipe(
            id: recipe2ID,
            ownerID: previewUserID,
            name: "Crispy Salmon Bowl",
            tags: ["quick", "fish", "healthy"],
            ingredients: [
                RecipeIngredient(quantity: "2", measurement: "", ingredient: "salmon fillets"),
                RecipeIngredient(quantity: "200", measurement: "g", ingredient: "sushi rice"),
                RecipeIngredient(quantity: "1", measurement: "", ingredient: "avocado"),
                RecipeIngredient(quantity: "2", measurement: "tbsp", ingredient: "spicy mayo")
            ],
            instructions: [
                "Pan sear salmon fillets skin-side down for 4 mins.",
                "Serve over warm sushi rice with edamame, avocado, cucumber, and spicy mayo."
            ],
            effort: .fifteenTo30,
            cuisine: "japanese"
        )
        let pasta = Recipe(
            id: recipe3ID,
            ownerID: previewUserID,
            name: "Cacio e Pepe",
            tags: ["pasta", "italian", "classic"],
            ingredients: [
                RecipeIngredient(quantity: "400", measurement: "g", ingredient: "spaghetti"),
                RecipeIngredient(quantity: "100", measurement: "g", ingredient: "Pecorino Romano"),
                RecipeIngredient(quantity: "1", measurement: "tbsp", ingredient: "black peppercorns")
            ],
            instructions: [
                "Toast freshly cracked black pepper in olive oil.",
                "Emulsify pasta water with Pecorino Romano cheese until velvety smooth."
            ],
            effort: .zeroTo15,
            cuisine: "italian"
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
            MealParty(mealID: meal1ID, partyID: partyID),
            MealParty(mealID: meal2ID, partyID: partyID),
            MealParty(mealID: meal1ID, partyID: publicPartyID),
            MealParty(mealID: meal2ID, partyID: publicPartyID),
            MealParty(mealID: meal1ID, partyID: discoverPartyID)
        ]

        // Recipe Favorites
        store.recipeFavorites = [
            RecipeFavorite(recipeID: recipe1ID, userID: previewUserID)
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
