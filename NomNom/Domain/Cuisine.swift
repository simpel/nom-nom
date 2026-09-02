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
}
