import SwiftUI

/// Segment of an editorial guest note with semantic color tone and typography weight.
struct GuestNoteSegment: Identifiable, Hashable {
    var id: String { text + "\(tone)" }
    let text: String
    let tone: Tone

    enum Tone: Hashable {
        case neutral
        case positive // dark green + semibold
        case negative // dark red + semibold
    }
}

/// Synthesizes short dinner-party guest notes for a host:
/// 1. Likes: [First name] [like-verb] [cuisine(s)] — [liked dish] [time] was a hit.
/// 2. Avoid: [Avoid-verb] [disliked category]; [disliked dish] [time] [negative-verb].
/// 3. Suggestion (optional): Next time, [1–2 dishes] would likely work.
enum GuestNoteSynthesizer {

    static func synthesize(
        firstName: String,
        ratedMeals: [(meal: Meal, rating: MealRating, recipe: Recipe)],
        topCuisines: [String],
        candidateRecipes: [Recipe]
    ) -> [GuestNoteSegment] {
        guard !ratedMeals.isEmpty else {
            return [GuestNoteSegment(text: "No dining history for \(firstName) yet.", tone: .neutral)]
        }

        let liked = ratedMeals
            .filter { $0.rating.score >= 0.60 }
            .sorted {
                if $0.rating.score != $1.rating.score {
                    return $0.rating.score > $1.rating.score
                }
                return $0.meal.eatenOn > $1.meal.eatenOn
            }
        let disliked = ratedMeals
            .filter { $0.rating.score <= 0.40 }
            .sorted {
                if $0.rating.score != $1.rating.score {
                    return $0.rating.score < $1.rating.score
                }
                return $0.meal.eatenOn > $1.meal.eatenOn
            }

        var segments: [GuestNoteSegment] = []

        // Sentence 1: Likes
        if let bestHit = liked.first {
            let hitDish = cleanDish(bestHit.recipe.name)
            let hitTime = naturalTime(for: bestHit.meal.eatenOn)

            segments.append(.init(text: "\(firstName) loves ", tone: .neutral))
            if topCuisines.count >= 2 {
                segments.append(.init(text: "\(topCuisines[0])", tone: .positive))
                segments.append(.init(text: " and ", tone: .neutral))
                segments.append(.init(text: "\(topCuisines[1]) food", tone: .positive))
            } else if let single = topCuisines.first {
                segments.append(.init(text: "\(single) food", tone: .positive))
            } else {
                segments.append(.init(text: "flavorful home-cooked food", tone: .positive))
            }
            segments.append(.init(text: " — the ", tone: .neutral))
            segments.append(.init(text: hitDish, tone: .positive))
            segments.append(.init(text: " \(hitTime) was a hit.", tone: .neutral))
        }

        // Sentence 2: Avoid
        if let miss = disliked.first {
            let missDish = cleanDish(miss.recipe.name)
            let missTime = naturalTime(for: miss.meal.eatenOn)
            let lower = miss.recipe.name.lowercased()

            if !segments.isEmpty { segments.append(.init(text: " ", tone: .neutral)) }

            if lower.contains("curry") || lower.contains("tandoori") || lower.contains("spic") || lower.contains("chili") || lower.contains("pepper") {
                let prefix = segments.isEmpty ? "\(firstName) leans away from " : "Steer clear of "
                segments.append(.init(text: prefix, tone: .neutral))
                segments.append(.init(text: "spicy dishes", tone: .negative))
                segments.append(.init(text: "; the ", tone: .neutral))
                segments.append(.init(text: missDish, tone: .negative))
                segments.append(.init(text: " \(missTime) fell flat.", tone: .neutral))
            } else if lower.contains("ratatouille") || lower.contains("stew") {
                let prefix = segments.isEmpty ? "\(firstName) is not a fan of " : "Not a fan of "
                segments.append(.init(text: prefix, tone: .neutral))
                segments.append(.init(text: missDish, tone: .negative))
                segments.append(.init(text: "; the one \(missTime) fell flat.", tone: .neutral))
            } else if let c = miss.recipe.cuisine, let formatted = Cuisine.formatDisplayName(c), !topCuisines.contains(formatted) {
                let prefix = segments.isEmpty ? "\(firstName) tends to avoid " : "Steer clear of "
                segments.append(.init(text: prefix, tone: .neutral))
                segments.append(.init(text: "\(formatted.lowercased()) dishes", tone: .negative))
                segments.append(.init(text: "; the ", tone: .neutral))
                segments.append(.init(text: missDish, tone: .negative))
                segments.append(.init(text: " \(missTime) didn't land.", tone: .neutral))
            } else {
                let prefix = segments.isEmpty ? "\(firstName) is not a fan of " : "Not a fan of "
                segments.append(.init(text: prefix, tone: .neutral))
                segments.append(.init(text: missDish, tone: .negative))
                segments.append(.init(text: "; the one \(missTime) didn't land.", tone: .neutral))
            }
        }

        // Sentence 3: Suggestion (only if history has >= 2 entries)
        if ratedMeals.count >= 2, !topCuisines.isEmpty {
            var suggestions: [String] = []
            let dislikedDishNames = disliked.map { cleanDish($0.recipe.name) }
            for r in candidateRecipes {
                guard let c = r.cuisine, let formatted = Cuisine.formatDisplayName(c), topCuisines.contains(formatted) else { continue }
                let cleaned = cleanDish(r.name)
                if dislikedDishNames.contains(where: { cleaned.contains($0) || $0.contains(cleaned) }) { continue }
                if !suggestions.contains(cleaned) {
                    suggestions.append(cleaned)
                    if suggestions.count == 2 { break }
                }
            }

            if !suggestions.isEmpty {
                if !segments.isEmpty { segments.append(.init(text: " ", tone: .neutral)) }
                if suggestions.count >= 2 {
                    segments.append(.init(text: "Next time, a ", tone: .neutral))
                    segments.append(.init(text: suggestions[0], tone: .positive))
                    segments.append(.init(text: " or ", tone: .neutral))
                    segments.append(.init(text: suggestions[1], tone: .positive))
                    segments.append(.init(text: " would likely work.", tone: .neutral))
                } else {
                    segments.append(.init(text: "Next time, ", tone: .neutral))
                    segments.append(.init(text: suggestions[0], tone: .positive))
                    segments.append(.init(text: " would likely work.", tone: .neutral))
                }
            }
        }

        return segments
    }

    private static func naturalTime(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: date), to: Calendar.current.startOfDay(for: .now)).day ?? 0
        let weeks = days / 7
        if days <= 1 { return "yesterday" }
        if weeks < 2 { return "last week" }
        if weeks <= 4 { return "a few weeks ago" }
        if weeks <= 8 { return "last month" }
        if weeks <= 52 {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM"
            return "in \(fmt.string(from: date))"
        }
        return "last year"
    }

    private static func cleanDish(_ dishName: String) -> String {
        var s = dishName
        for prefix in ["Classic ", "classic ", "Traditional ", "traditional ", "Delicious ", "delicious "] {
            if s.hasPrefix(prefix) { s = String(s.dropFirst(prefix.count)) }
        }
        return s.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
