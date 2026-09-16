import Foundation
import Supabase

extension FoodStore {
    
    /// Fetches the cached insights for a given party.
    func fetchInsights(for partyID: UUID) async throws -> PartyInsights? {
        do {
            let result: [PartyInsights] = try await supabase.database
                .from("party_insights")
                .select()
                .eq("party_id", value: partyID)
                .execute()
                .value
            return result.first
        } catch {
            Self.log.error("Failed to fetch party insights for \(partyID, privacy: .public): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Calculates the average score per meal for the currently selected party (trendline).
    /// Uses local data.
    var currentPartyTrendline: [(date: Date, averageScore: Double)] {
        guard let currentParty else { return [] }
        return trendline(forParty: currentParty.id)
    }

    /// Calculates the average score per meal for a given party (trendline). Uses local data.
    func trendline(forParty partyID: UUID) -> [(date: Date, averageScore: Double)] {
        trendline(forMeals: meals(forParty: partyID))
    }

    /// Calculates the average score per meal across an arbitrary set of meals (trendline).
    /// Uses local data.
    func trendline(forMeals meals: [Meal]) -> [(date: Date, averageScore: Double)] {
        let meals = meals.sorted(by: { $0.eatenOn < $1.eatenOn })
        var trend: [(date: Date, averageScore: Double)] = []

        for meal in meals {
            let ratings = ratingsByMeal[meal.id] ?? []
            if ratings.isEmpty { continue }

            let totalScore = ratings.reduce(0.0) { $0 + $1.reaction.score }
            let avgScore = totalScore / Double(ratings.count)
            trend.append((meal.eatenOn, avgScore))
        }

        return trend
    }

    /// Calculates the currently selected party's score trend broken down per rater
    /// (party member or household eater). Uses local data. Ordered "Me" first, then
    /// alphabetically — a stable order so a chart can assign colors by index.
    var currentPartyMemberTrendlines: [MemberTrendSeries] {
        guard let currentParty else { return [] }
        return memberTrendlines(forParty: currentParty.id)
    }

    /// Calculates a given party's score trend broken down per rater (party member or
    /// household eater). Uses local data.
    func memberTrendlines(forParty partyID: UUID) -> [MemberTrendSeries] {
        let meals = meals(forParty: partyID).sorted(by: { $0.eatenOn < $1.eatenOn })

        var pointsByRater: [RaterRef: [(date: Date, score: Double)]] = [:]
        for meal in meals {
            for rating in ratingsByMeal[meal.id] ?? [] {
                pointsByRater[rating.source, default: []].append((meal.eatenOn, rating.reaction.score))
            }
        }

        return pointsByRater.keys.sorted { a, b in
            if a.id == userID { return true }
            if b.id == userID { return false }
            return label(for: a).name.localizedStandardCompare(label(for: b).name) == .orderedAscending
        }.map { ref in
            let who = label(for: ref)
            return MemberTrendSeries(ref: ref, name: who.name, emoji: who.emoji, points: pointsByRater[ref] ?? [])
        }
    }

    /// Calculates the aggregate health metrics for the currently selected party.
    /// Uses local data.
    var currentPartyHealthInsights: PartyHealthInsights? {
        guard let currentParty else { return nil }
        return healthInsights(forParty: currentParty.id)
    }

    /// Calculates the aggregate health metrics for a given party. Uses local data.
    func healthInsights(forParty partyID: UUID) -> PartyHealthInsights? {
        healthInsights(forMeals: meals(forParty: partyID))
    }

    /// Calculates the aggregate health metrics across an arbitrary set of meals. Uses local data.
    func healthInsights(forMeals meals: [Meal]) -> PartyHealthInsights? {
        let meals = meals.sorted(by: { $0.eatenOn < $1.eatenOn })
        var totalHealthScore = 0
        var healthScoreCount = 0
        var tierCounts: [HealthTier: Int] = [:]
        
        var totalCals = 0.0, totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0
        var macrosCount = 0
        
        var strengthCounts: [String: Int] = [:]
        var considerationCounts: [String: Int] = [:]
        
        var trend: [(date: Date, averageHealthScore: Double)] = []

        for meal in meals {
            guard let recipe = dishByID[meal.dishID], let healthIndex = recipe.healthIndex else { continue }
            
            totalHealthScore += healthIndex.score
            healthScoreCount += 1
            
            tierCounts[healthIndex.tier, default: 0] += 1
            
            if let macros = healthIndex.breakdown?.macros {
                if let cals = macros.calories {
                    totalCals += Double(cals)
                    totalProtein += macros.proteinGrams ?? 0
                    totalCarbs += macros.carbsGrams ?? 0
                    totalFat += macros.fatGrams ?? 0
                    macrosCount += 1
                }
            }
            
            for positive in healthIndex.breakdown?.positives ?? [] {
                strengthCounts[positive, default: 0] += 1
            }
            
            for consideration in healthIndex.breakdown?.considerations ?? [] {
                considerationCounts[consideration, default: 0] += 1
            }
            
            trend.append((meal.eatenOn, Double(healthIndex.score)))
        }
        
        guard healthScoreCount > 0 else { return nil }
        
        let avgHealthScore = totalHealthScore / healthScoreCount
        
        var distribution: [HealthTier: Double] = [:]
        for (tier, count) in tierCounts {
            distribution[tier] = Double(count) / Double(healthScoreCount)
        }
        
        var avgMacros: MacroNutrients? = nil
        if macrosCount > 0 {
            avgMacros = MacroNutrients(
                calories: Int(totalCals / Double(macrosCount)),
                proteinGrams: totalProtein / Double(macrosCount),
                carbsGrams: totalCarbs / Double(macrosCount),
                fatGrams: totalFat / Double(macrosCount)
            )
        }
        
        let topStrengths = Array(strengthCounts.sorted { $0.value > $1.value }.prefix(3).map(\.key))
        let topConsiderations = Array(considerationCounts.sorted { $0.value > $1.value }.prefix(3).map(\.key))
        
        return PartyHealthInsights(
            averageHealthScore: avgHealthScore,
            healthTierDistribution: distribution,
            topStrengths: topStrengths,
            topConsiderations: topConsiderations,
            averageMacros: avgMacros,
            healthScoreTrend: trend
        )
    }
}
