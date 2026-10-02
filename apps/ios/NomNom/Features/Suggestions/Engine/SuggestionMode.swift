import Foundation

// MARK: - Modes

enum SuggestionMode: String, CaseIterable, Identifiable {
    case balanced
    case crowdPleasers
    case longTime
    case adventurous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: return "Balanced"
        case .crowdPleasers: return "Crowd pleasers"
        case .longTime: return "Long time no see"
        case .adventurous: return "Adventurous"
        }
    }

    var shortTitle: String {
        switch self {
        case .balanced: return "Balanced"
        case .crowdPleasers: return "Favourites"
        case .longTime: return "Overdue"
        case .adventurous: return "New"
        }
    }

    var explanation: String {
        switch self {
        case .balanced:
            return "Food they liked that we haven't had for a while, with a nudge towards dishes we've only tried once or twice."
        case .crowdPleasers:
            return "Safe bets. Ranked almost purely on how much the kids liked it, and hard on anything somebody disliked."
        case .longTime:
            return "Rotation first. Dishes we're overdue for, even if they're only moderately popular."
        case .adventurous:
            return "Leans on the dishes we know least about, so the ratings get more reliable over time."
        }
    }

    var symbol: String {
        switch self {
        case .balanced: return "scalemass"
        case .crowdPleasers: return "heart.fill"
        case .longTime: return "clock.arrow.circlepath"
        case .adventurous: return "sparkles"
        }
    }

    var weights: SuggestionWeights {
        switch self {
        case .balanced: return .balanced
        case .crowdPleasers: return .crowdPleasers
        case .longTime: return .longTime
        case .adventurous: return .adventurous
        }
    }
}

// MARK: - Filters

struct SuggestionFilters: Equatable {
    var mode: SuggestionMode = .balanced
    /// Only keep dishes these people are known to like. Keyed by `RaterRef` rather
    /// than an eater id, so "must be liked by" can name a household member or an
    /// account holder — both leave verdicts now.
    var requiredRaters: Set<RaterRef> = []
    /// Hide anything cooked more recently than this many days ago.
    var minDaysSinceServed: Int = 0
    /// Drop dishes where somebody's recent verdict was a flat no.
    var hideDisliked: Bool = true
    /// Keep dishes that exist but have no verdicts yet.
    var includeUntried: Bool = true
    var searchText: String = ""

    var isDefault: Bool {
        requiredRaters.isEmpty
            && minDaysSinceServed == 0
            && hideDisliked
            && includeUntried
            && searchText.isEmpty
    }

    /// Number of non-default knobs, for the toolbar badge.
    var activeCount: Int {
        var n = 0
        if !requiredRaters.isEmpty { n += 1 }
        if minDaysSinceServed > 0 { n += 1 }
        if !hideDisliked { n += 1 }
        if !includeUntried { n += 1 }
        return n
    }
}
