import Foundation

/// The questions of the rate-a-meal flow, one per screen, in order. Only taste is
/// required; the rest can be skipped.
enum RateQuestion: String, CaseIterable, Identifiable, Hashable {
    case taste, tags, plate, again

    var id: String { rawValue }

    /// The screen's ScreenHeader title.
    var title: String {
        switch self {
        case .taste: return "How was it?"
        case .tags: return "What stood out?"
        case .plate: return "How much did you eat?"
        case .again: return "Want it again?"
        }
    }

    /// The row title on the review screen.
    var reviewTitle: String {
        switch self {
        case .taste: return "Taste"
        case .tags: return "What stood out"
        case .plate: return "How much you ate"
        case .again: return "Want it again"
        }
    }

    var summary: String? {
        self == .tags ? "Pick as many as you like." : nil
    }

    /// Single-choice questions move on as soon as something is picked.
    var advancesOnPick: Bool { self != .tags }

    var next: RateStep {
        switch self {
        case .taste: return .question(.tags)
        case .tags: return .question(.plate)
        case .plate: return .question(.again)
        case .again: return .review
        }
    }

    /// The answer as one line on the review screen. `tagLabels` are the chosen tags'
    /// labels (`FoodStore.ratingTagLabels`).
    func answer(in answers: RatingAnswers, tagLabels: [String]) -> String {
        switch self {
        case .taste:
            guard let reaction = answers.reaction else { return "Not rated" }
            return "\(TasteScoreSelector.glyph(for: reaction)) \u{00B7} \(reaction.name)"
        case .tags:
            return tagLabels.isEmpty ? "Skipped" : tagLabels.joined(separator: ", ")
        case .plate:
            return answers.plate?.label ?? "Skipped"
        case .again:
            return answers.again?.label ?? "Skipped"
        }
    }
}

/// A screen pushed onto the rate sheet's navigation path.
enum RateStep: Hashable {
    case question(RateQuestion)
    case review
}
