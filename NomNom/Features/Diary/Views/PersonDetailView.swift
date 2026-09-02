import SwiftUI

/// Shows everything one person has eaten, when they ate it, how they rated it,
/// their top favorites and dislikes, and an AI-driven taste profile summary.
struct PersonDetailView: View {
    let raterRef: RaterRef

    @Environment(FoodStore.self) private var store

    private var label: (emoji: String, name: String) {
        store.label(for: raterRef)
    }

    private var personTypeDescription: String {
        switch raterRef {
        case .eater:
            return "Household member"
        case .account(let id):
            return id == store.userID ? "You" : "Account guest"
        }
    }

    private var personRatings: [MealRating] {
        store.ratings(for: raterRef)
    }

    private var meals: [Meal] {
        var mealSet: [UUID: Meal] = [:]
        for rating in personRatings {
            if let meal = store.meal(rating.mealID) {
                mealSet[meal.id] = meal
            }
        }
        if case .account(let id) = raterRef {
            for meal in store.meals where meal.createdBy == id {
                mealSet[meal.id] = meal
            }
        }
        return mealSet.values.sorted { $0.eatenOn > $1.eatenOn }
    }

    private var ratingCounts: [Reaction: Int] {
        var counts: [Reaction: Int] = [:]
        for r in personRatings {
            counts[r.reaction, default: 0] += 1
        }
        return counts
    }

    private var positiveRatingsCount: Int {
        personRatings.filter(\.reaction.isPositive).count
    }

    private var favoriteDishes: [Dish] {
        let positive = personRatings.filter { $0.reaction.isPositive }
        var dishIDs = Set<UUID>()
        for rating in positive {
            if let meal = store.meal(rating.mealID) {
                dishIDs.insert(meal.dishID)
            }
        }
        return dishIDs.compactMap { store.dish($0) }.sorted { $0.name < $1.name }
    }

    private var dislikedDishes: [Dish] {
        let negative = personRatings.filter { $0.reaction.isNegative }
        var dishIDs = Set<UUID>()
        for rating in negative {
            if let meal = store.meal(rating.mealID) {
                dishIDs.insert(meal.dishID)
            }
        }
        return dishIDs.compactMap { store.dish($0) }.sorted { $0.name < $1.name }
    }

    private var topTags: [String] {
        var tagCounts: [String: Int] = [:]
        for dish in favoriteDishes {
            for tag in dish.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts.sorted { $0.value > $1.value }.map(\.key)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection

                PersonTasteBreakdownCard(
                    summary: generatedTasteSummary,
                    topTags: topTags,
                    ratingCounts: ratingCounts,
                    totalRatingsCount: personRatings.count
                )

                if !favoriteDishes.isEmpty {
                    PersonDishRatingsList(title: "Favorite Dishes", dishes: favoriteDishes)
                }

                if !dislikedDishes.isEmpty {
                    PersonDishRatingsList(title: "Disliked Dishes", dishes: dislikedDishes, isDisliked: true)
                }

                PersonMealHistorySection(
                    personName: label.name,
                    raterRef: raterRef,
                    meals: meals
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .screenTitle(label.name)
    }

    private var headerSection: some View {
        SectionCard {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Text(label.name.prefix(1).uppercased())
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 4) {
                    Text(label.name)
                        .font(.title2.bold())
                    Text(personTypeDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    StatPill(title: "Meals", value: "\(meals.count)")
                    StatPill(title: "Ratings", value: "\(personRatings.count)")
                    if !personRatings.isEmpty {
                        let positivePercent = Int((Double(positiveRatingsCount) / Double(personRatings.count)) * 100)
                        StatPill(title: "Positive", value: "\(positivePercent)%")
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    private var generatedTasteSummary: String {
        let name = label.name
        if personRatings.isEmpty {
            return "\(name) hasn't rated enough meals yet. As they taste and rate more dishes, their AI taste profile and flavor preferences will be automatically generated here."
        }

        var parts: [String] = []

        if !favoriteDishes.isEmpty {
            let names = favoriteDishes.prefix(3).map(\.name).joined(separator: ", ")
            parts.append("\(name) loves dishes like \(names).")
        }

        if !topTags.isEmpty {
            let tags = topTags.prefix(3).joined(separator: ", ")
            parts.append("Has a strong preference for recipes tagged with \(tags).")
        }

        if !dislikedDishes.isEmpty {
            let disliked = dislikedDishes.prefix(2).map(\.name).joined(separator: ", ")
            parts.append("Generally dislikes \(disliked).")
        }

        let positiveRate = Double(positiveRatingsCount) / Double(personRatings.count)
        if positiveRate > 0.6 {
            parts.append("An enthusiastic eater who enjoys most dinner selections.")
        } else if positiveRate < 0.3 {
            parts.append("Selective taste profile — responds best to familiar comfort foods.")
        }

        return parts.joined(separator: " ")
    }
}

private struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let eater = store.eaters.first {
            PersonDetailView(raterRef: .eater(eater.id))
        }
    }
}

