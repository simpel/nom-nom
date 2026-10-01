import Foundation

/// Recommendation for a party member pairing high personal taste appeal with party compatibility.
struct PartyMemberRecipeRecommendation: Identifiable, Hashable {
    var id: UUID { recipe.id }
    let recipe: Recipe
    let userFitScore: Int // 0-100 percentage
    let partyFitScore: Int // 0-100 percentage
}

/// A specific meal rated by a member in this party, comparing their reaction against the party consensus.
struct PartyMemberMealRecord: Identifiable, Hashable {
    var id: UUID { meal.id }
    let meal: Meal
    let recipeName: String
    let userReaction: Reaction
    let userScore: Int
    let partyAverageScore: Int
    var delta: Int { userScore - partyAverageScore }
}

extension FoodStore {

    /// Short dinner-party guest notes segments for a host with semantic tones.
    func nextDinnerTipSegments(for rater: RaterRef, partyID: UUID) -> [GuestNoteSegment] {
        let name = firstName(for: rater)
        let raterRatings = ratings(for: rater)
        let ratedMeals: [(meal: Meal, rating: MealRating, recipe: Recipe)] = raterRatings.compactMap { rating in
            guard let m = meal(rating.mealID), let r = recipe(m.dishID) else { return nil }
            return (m, rating, r)
        }.sorted { $0.meal.eatenOn > $1.meal.eatenOn }

        let liked = ratedMeals.filter { $0.rating.reaction.score >= 0.60 }
        var cuisineCounts: [String: Int] = [:]
        for item in liked {
            if let c = item.recipe.cuisine, let formatted = Cuisine.formatDisplayName(c) {
                cuisineCounts[formatted, default: 0] += 1
            }
        }
        var topCuisines = cuisineCounts.sorted { $0.value > $1.value }.map(\.key)
        if topCuisines.isEmpty {
            topCuisines = cuisineAffinities(for: rater).filter { $0.delta > 0.05 }.compactMap { Cuisine.formatDisplayName($0.tag) }
        }

        return GuestNoteSynthesizer.synthesize(
            firstName: name,
            ratedMeals: ratedMeals,
            topCuisines: topCuisines,
            candidateRecipes: recipes
        )
    }

    /// Short dinner-party guest notes for a host (plain string representation).
    func nextDinnerTip(for rater: RaterRef, partyID: UUID) -> String {
        nextDinnerTipSegments(for: rater, partyID: partyID).map(\.text).joined()
    }

    /// Curates recipes from the library with dual scoring: high appeal for the individual, plus table fit for the party.
    func memberPartyRecommendations(for rater: RaterRef, partyID: UUID) -> [PartyMemberRecipeRecommendation] {
        let allRecipes = recipes
        guard !allRecipes.isEmpty else { return [] }

        let raterRatings = ratings(for: rater)
        let ratingsByRecipeID = Dictionary(grouping: raterRatings, by: { rating -> UUID in
            meal(rating.mealID)?.dishID ?? UUID()
        })

        let kindAffinities = Dictionary(uniqueKeysWithValues: dishKindAffinities(for: rater).map { ($0.tag, $0.delta) })
        let cuisineAffs = Dictionary(uniqueKeysWithValues: cuisineAffinities(for: rater).map { ($0.tag, $0.delta) })

        let partyMeals = meals(forParty: partyID)
        var partyScoresByDish: [UUID: [Double]] = [:]
        for meal in partyMeals {
            let ratings = ratingsByMeal[meal.id] ?? []
            if !ratings.isEmpty {
                let avg = ratings.reduce(0.0) { $0 + $1.reaction.score } / Double(ratings.count)
                partyScoresByDish[meal.dishID, default: []].append(avg)
            }
        }

        var results: [PartyMemberRecipeRecommendation] = []

        for recipe in allRecipes {
            var userScore: Double = 0.85
            if let prior = ratingsByRecipeID[recipe.id]?.first {
                userScore = prior.reaction.score
            } else {
                if let kind = dishKind(for: recipe), let delta = kindAffinities[kind.slug] {
                    userScore += delta * 0.5
                }
                if let cuisine = recipe.cuisine, let delta = cuisineAffs[cuisine.lowercased()] {
                    userScore += delta * 0.5
                }
            }
            let userFit = max(60, min(99, Int((userScore * 100.0).rounded())))

            var partyScore: Double = 0.82
            if let dishPartyScores = partyScoresByDish[recipe.id], !dishPartyScores.isEmpty {
                partyScore = dishPartyScores.reduce(0.0, +) / Double(dishPartyScores.count)
            }
            let partyFit = max(60, min(98, Int((partyScore * 100.0).rounded())))

            results.append(
                PartyMemberRecipeRecommendation(
                    recipe: recipe,
                    userFitScore: userFit,
                    partyFitScore: partyFit
                )
            )
        }

        return results
            .sorted { ($0.userFitScore * 2 + $0.partyFitScore) > ($1.userFitScore * 2 + $1.partyFitScore) }
            .prefix(8)
            .map { $0 }
    }

    /// History of this member's ratings on dinners served in this party.
    func memberPartyDinnerHistory(
        for rater: RaterRef,
        partyID: UUID
    ) -> (highest: [PartyMemberMealRecord], lowest: [PartyMemberMealRecord]) {
        let partyMeals = meals(forParty: partyID)
        var records: [PartyMemberMealRecord] = []

        for meal in partyMeals {
            let mealRatings = ratingsByMeal[meal.id] ?? []
            guard let rating = mealRatings.first(where: { $0.source == rater }),
                  let recipe = recipe(meal.dishID) else { continue }

            let partyAvg = mealRatings.reduce(0.0) { $0 + $1.reaction.score } / Double(max(1, mealRatings.count))
            let userScoreInt = Int((rating.reaction.score * 100.0).rounded())
            let partyAvgInt = Int((partyAvg * 100.0).rounded())

            records.append(
                PartyMemberMealRecord(
                    meal: meal,
                    recipeName: recipe.name,
                    userReaction: rating.reaction,
                    userScore: userScoreInt,
                    partyAverageScore: partyAvgInt
                )
            )
        }

        let sortedByScore = records.sorted { $0.userScore > $1.userScore }
        let highest = Array(sortedByScore.prefix(2))
        let lowest = Array(sortedByScore.reversed().filter { rec in
            !highest.contains(where: { $0.id == rec.id })
        }.prefix(1))

        return (highest: highest, lowest: lowest)
    }
}
