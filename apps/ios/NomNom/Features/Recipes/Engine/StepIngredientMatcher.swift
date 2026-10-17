import Foundation

/// What cook mode shows under a step: the ingredients it uses, every ingredient (when
/// the step clearly adds something but we can't tell what), or nothing (a step like
/// "Preheat the oven to 200°").
enum StepIngredients: Equatable {
    case matched([Int])
    case all
    case none
}

/// Works out a step's ingredients from two sources: the `analyze-recipe-steps` indexes
/// (missing until the analysis has run, and stale for a moment after the steps are
/// edited) and the step's own words matched against the ingredient names. The two are
/// merged, so an ingredient the analysis missed but the step names still shows.
enum StepIngredientMatcher {

    /// - Parameters:
    ///   - step: the instruction text.
    ///   - ingredients: every ingredient name in order (`Recipe.ingredients`).
    ///   - analyzed: the analysis's indexes for this step, nil when there is none.
    static func ingredients(for step: String, ingredients: [String], analyzed: [Int]?) -> StepIngredients {
        guard !ingredients.isEmpty else { return .none }
        let fromAnalysis = (analyzed ?? []).filter { ingredients.indices.contains($0) }
        let fromText = textMatches(step, ingredients: ingredients)
        let merged = Array(Set(fromAnalysis).union(fromText)).sorted()
        if !merged.isEmpty { return .matched(merged) }
        return addsSomething(step) ? .all : .none
    }

    /// Indexes of the ingredients whose name the step mentions.
    static func textMatches(_ step: String, ingredients: [String]) -> [Int] {
        let words = tokens(step)
        guard !words.isEmpty else { return [] }
        return ingredients.indices.filter { i in
            keywords(ingredients[i]).contains { keyword in words.contains { mentions($0, keyword) } }
        }
    }

    // MARK: - Matching

    /// A step word names an ingredient keyword: the same word, a plural or definite
    /// form ("tomatoes", "löken"), or a compound that contains it ("vitlöksklyftor").
    private static func mentions(_ word: String, _ keyword: String) -> Bool {
        if word == keyword || word.hasPrefix(keyword) { return true }
        if keyword.count >= 4, word.count >= 4, keyword.hasPrefix(word) { return true }
        return keyword.count >= 5 && word.contains(keyword)
    }

    /// The words of an ingredient name that identify it: the part before a comma or
    /// bracket ("onion, finely chopped (about 200 g)" → "onion"), minus amounts,
    /// preparation and size words.
    private static func keywords(_ name: String) -> [String] {
        let head = name.split(whereSeparator: { ",(;".contains($0) }).first.map(String.init) ?? name
        return tokens(head).filter { !descriptors.contains($0) }
    }

    private static func tokens(_ text: String) -> [String] {
        text.normalizedForMatching
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 3 && !$0.allSatisfy(\.isNumber) && !stopWords.contains($0) }
            .map(singular)
    }

    /// "tomatoes" → "tomato", "carrots" → "carrot"; short words are left alone.
    private static func singular(_ word: String) -> String {
        if word.count > 4, word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    /// Whether the step puts something in the pot: "Add the spices", "Season to
    /// taste", "Blanda allt". Such a step uses ingredients even when it doesn't name them.
    private static func addsSomething(_ step: String) -> Bool {
        let words = step.normalizedForMatching.split(separator: " ").map(String.init)
        return words.contains { word in addCues.contains { word.hasPrefix($0) } }
    }

    // Accent-folded, like `normalizedForMatching` ("lagg" is "lägg").
    private static let addCues: [String] = [
        "add", "mix", "stir", "combine", "season", "toss", "pour", "whisk", "fold",
        "sprinkle", "blend", "marinate", "rub", "coat", "garnish", "drizzle", "beat",
        "knead", "dress", "ingredient",
        "tillsatt", "lagg", "blanda", "ror", "hall", "krydda", "vispa", "stro",
        "vand", "smaksatt", "fordela", "ringla", "toppa", "ingrediens",
    ]

    private static let stopWords: Set<String> = [
        "and", "the", "for", "with", "into", "from", "until", "about", "each", "then",
        "och", "med", "till", "eller", "som", "den", "det", "pinch", "dash",
        "cup", "cups", "tbsp", "tsp", "gram", "grams", "msk", "tsk", "krm",
    ]

    private static let descriptors: Set<String> = [
        "fresh", "dried", "large", "small", "medium", "chopped", "diced", "sliced",
        "minced", "grated", "ground", "whole", "finely", "roughly", "optional", "extra",
        "virgin", "unsalted", "salted", "boneless", "skinless", "ripe", "cold", "warm",
        "hot", "frozen", "cooked", "raw", "peeled", "crushed", "taste", "serve", "serving",
        "farsk", "torkad", "stor", "liten", "hackad", "finhackad", "riven", "skivad",
        "malen", "kokt", "fryst", "smak", "servering",
    ]
}
