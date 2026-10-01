import SwiftUI

/// How an eater reacted to a dish on a scale of -1 to 5:
/// - `-1`: Can't eat
/// - `1`: Bad
/// - `2`: Meh
/// - `3`: Good
/// - `4`: Great
/// - `5`: Amazing
enum Reaction: Int, Codable, CaseIterable, Identifiable, Hashable, Comparable, TactilePickerOption {
    case inedible = -1
    case bad = 1
    case meh = 2
    case good = 3
    case great = 4
    case amazing = 5

    var id: Int { rawValue }

    /// The verdict for a normalised 0...1 score (averages, recency-weighted
    /// scores). The single source of the score→verdict thresholds.
    init(score: Double) {
        switch score {
        case 0.85...: self = .amazing
        case 0.70..<0.85: self = .great
        case 0.50..<0.70: self = .good
        case 0.30..<0.50: self = .meh
        case 0.15..<0.30: self = .bad
        default: self = .inedible
        }
    }

    static func < (lhs: Reaction, rhs: Reaction) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Normalised 0...1 score used by the suggestion engine.
    var score: Double {
        switch self {
        case .inedible: return 0.0
        case .bad: return 0.2
        case .meh: return 0.4
        case .good: return 0.6
        case .great: return 0.8
        case .amazing: return 1.0
        }
    }

    var systemImage: String {
        switch self {
        case .inedible: return "xmark.circle.fill"
        case .bad: return "hand.thumbsdown.fill"
        case .meh: return "minus.circle.fill"
        case .good: return "hand.thumbsup"
        case .great: return "hand.thumbsup.fill"
        case .amazing: return "star.fill"
        }
    }

    var numberLabel: String {
        switch self {
        case .inedible: return "-1"
        case .bad: return "1"
        case .meh: return "2"
        case .good: return "3"
        case .great: return "4"
        case .amazing: return "5"
        }
    }

    // MARK: - TactilePickerOption Conformance

    var label: String { numberLabel }
    var icon: String? { nil }
    var description: String? { nil }

    var name: String {
        switch self {
        case .inedible: return "Can't eat"
        case .bad: return "Bad"
        case .meh: return "Meh"
        case .good: return "Good"
        case .great: return "Great"
        case .amazing: return "Amazing"
        }
    }

    var shortLabel: String {
        switch self {
        case .inedible: return "Can't eat"
        case .bad: return "Bad"
        case .meh: return "Meh"
        case .good: return "Good"
        case .great: return "Great"
        case .amazing: return "Amazing"
        }
    }

    /// Paints shapes: tint grounds, selected borders, dots. Never carries text.
    var fill: Color {
        switch self {
        case .inedible: return DS.Color.reactionInedibleFill
        case .bad: return DS.Color.reactionBadFill
        case .meh: return DS.Color.reactionMehFill
        case .good: return DS.Color.reactionGoodFill
        case .great: return DS.Color.reactionGreatFill
        case .amazing: return DS.Color.reactionAmazingFill
        }
    }

    /// Ink for the reaction's numeral or word.
    var text: Color {
        switch self {
        case .inedible: return DS.Color.reactionInedibleText
        case .bad: return DS.Color.reactionBadText
        case .meh: return DS.Color.reactionMehText
        case .good: return DS.Color.reactionGoodText
        case .great: return DS.Color.reactionGreatText
        case .amazing: return DS.Color.reactionAmazingText
        }
    }

    var tint: Color { fill }

    var isPositive: Bool { rawValue >= 4 }
    var isNegative: Bool { rawValue <= 1 }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        self = Self.fromRaw(raw)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func fromRaw(_ raw: Int) -> Reaction {
        switch raw {
        case -1: return .inedible
        case 0: return .bad
        case 1: return .bad
        case 2: return .meh
        case 3: return .good
        case 4: return .great
        case 5: return .amazing
        default:
            if raw < -1 { return .inedible }
            if raw > 5 { return .amazing }
            return .good
        }
    }
}
