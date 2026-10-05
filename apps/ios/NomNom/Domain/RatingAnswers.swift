import Foundation

/// What one eater says about one meal, beyond the verdict. Every answer belongs to the
/// person giving it (`meal_ratings`, one row per rater): nobody rates for anybody else.
/// The tags come from the `rating_tags` catalogue (`RatingTagOption`).

/// How much of the plate the eater ate. Stored as `meal_ratings.plate` (0–3).
enum PlateCleared: Int, CaseIterable, Identifiable {
    case bites = 0, half, cleared, seconds

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .bites: return "A few bites"
        case .half: return "Half"
        case .cleared: return "Cleared"
        case .seconds: return "Had seconds"
        }
    }

    /// Share of a portion eaten, in percent: drawn as a Bar against `maxPortion`.
    var portion: Double {
        switch self {
        case .bites: return 25
        case .half: return 50
        case .cleared: return 100
        case .seconds: return 125
        }
    }

    static let maxPortion: Double = 125
}

/// Whether the eater wants the meal again, apart from how it tasted. Stored as
/// `meal_ratings.again` (0–2).
enum WantAgain: Int, CaseIterable, Identifiable {
    case never = 0, sometime, soon

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .never: return "Not again"
        case .sometime: return "Sometime"
        case .soon: return "Soon"
        }
    }

    var description: String {
        switch self {
        case .never: return "Not for me"
        case .sometime: return "In a while"
        case .soon: return "Within weeks"
        }
    }
}

/// The viewer's draft while rating a meal: the verdict is required, the rest optional.
struct RatingAnswers: Equatable {
    var reaction: Reaction?
    /// `rating_tags` ids.
    var tags: Set<String> = []
    var plate: PlateCleared?
    var again: WantAgain?
    var note: String = ""

    init() {}

    init(_ rating: MealRating?) {
        guard let rating else { return }
        reaction = rating.reaction
        tags = Set(rating.tags)
        plate = rating.plate
        again = rating.again
        note = rating.note ?? ""
    }
}
