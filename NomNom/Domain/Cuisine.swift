import Foundation

/// Standard cuisine / kitchen classifications for recipes.
enum Cuisine: String, Codable, CaseIterable, Identifiable, Hashable {
    case asian = "asian"
    case mexican = "mexican"
    case italian = "italian"
    case nordic = "nordic"
    case mediterranean = "mediterranean"
    case indian = "indian"
    case middleEastern = "middle_eastern"
    case american = "american"
    case french = "french"
    case japanese = "japanese"
    case thai = "thai"
    case korean = "korean"
    case greek = "greek"
    case spanish = "spanish"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .asian: return "Asian"
        case .mexican: return "Mexican"
        case .italian: return "Italian"
        case .nordic: return "Nordic"
        case .mediterranean: return "Mediterranean"
        case .indian: return "Indian"
        case .middleEastern: return "Middle Eastern"
        case .american: return "American"
        case .french: return "French"
        case .japanese: return "Japanese"
        case .thai: return "Thai"
        case .korean: return "Korean"
        case .greek: return "Greek"
        case .spanish: return "Spanish"
        }
    }

    static func matching(from query: String) -> Cuisine? {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }
        return allCases.first {
            $0.rawValue == normalized ||
            $0.displayName.lowercased() == normalized ||
            $0.displayName.lowercased().hasPrefix(normalized)
        }
    }

    static func formatDisplayName(_ raw: String?) -> String? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if let preset = matching(from: raw) {
            return preset.displayName
        }
        return raw.capitalized
    }

    var assetImageName: String {
        switch self {
        case .asian: return "Cuisines/asian"
        case .mexican: return "Cuisines/mexican"
        case .italian: return "Cuisines/italian"
        case .nordic: return "Cuisines/swedish"
        case .mediterranean: return "Cuisines/mediterranean"
        case .indian: return "Cuisines/indian"
        case .middleEastern: return "Cuisines/middle-eastern"
        case .american: return "Cuisines/american"
        case .french: return "Cuisines/french"
        case .japanese: return "Cuisines/japanese"
        case .thai: return "Cuisines/thai"
        case .korean: return "Cuisines/korean"
        case .greek: return "Cuisines/greek"
        case .spanish: return "Cuisines/spanish"
        }
    }

    static func assetImageName(for query: String?) -> String? {
        guard let query, let cuisine = matching(from: query) else { return nil }
        return cuisine.assetImageName
    }
}
