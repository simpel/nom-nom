import Foundation

/// What cook mode knows about one instruction step (`dishes.instruction_details`, filled
/// by the `analyze-recipe-steps` edge function): how long it waits on, and which of the
/// recipe's ingredients it uses.
struct RecipeStepDetail: Hashable, Codable {
    /// Minutes the step waits on (a timer), or nil when it is hands-on.
    var minutes: Int?
    /// Indexes into `Recipe.ingredients`.
    var ingredients: [Int]

    init(minutes: Int? = nil, ingredients: [Int] = []) {
        self.minutes = minutes
        self.ingredients = ingredients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minutes = try container.decodeIfPresent(Int.self, forKey: .minutes)
        ingredients = try container.decodeIfPresent([Int].self, forKey: .ingredients) ?? []
    }
}

extension Recipe {
    /// Step details that still line up with `instructions` (nil once the steps were
    /// edited, so cook mode re-analyses them).
    var currentStepDetails: [RecipeStepDetail]? {
        guard let instructionDetails, instructionDetails.count == instructions.count else { return nil }
        return instructionDetails
    }
}
