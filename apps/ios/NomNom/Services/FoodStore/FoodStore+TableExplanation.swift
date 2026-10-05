import Foundation

/// Why the whole table scored a meal the way it did: the per-rater explanation
/// (`raterExplanation(for:meal:)`) merged across everyone who rated, plus the
/// "what stood out" tags they picked. On device, no LLM call. Feeds the Pro card on the
/// meal score sheet and the "What pulled it down" section of its Pro sheet.
extension FoodStore {

    /// Every reason, tags first (they are about this meal), then history patterns by
    /// size of effect. Negative and positive reasons both come back; callers split them.
    func tableExplanation(forMeal meal: Meal) -> [TableReason] {
        tagReasons(forMeal: meal) + patternReasons(forMeal: meal)
    }

    /// The reasons that pulled the score down, most damaging first.
    func tableReasonsDown(forMeal meal: Meal) -> [TableReason] {
        tableExplanation(forMeal: meal).filter(\.isNegative)
    }

    // MARK: - Tags

    private func tagReasons(forMeal meal: Meal) -> [TableReason] {
        let ratings = ratings(forMeal: meal.id)
        guard !ratings.isEmpty else { return [] }
        let catalogue = Dictionary(ratingTags.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var raters: [String: [String]] = [:]
        for rating in ratings {
            let name = rating.source == .account(userID) ? "You" : firstName(for: rating.source)
            for tag in rating.tags { raters[tag, default: []].append(name) }
        }

        return raters.compactMap { tagID, names -> TableReason? in
            guard let option = catalogue[tagID], !option.isPositive else { return nil }
            return TableReason(
                source: .tag(id: tagID),
                title: option.label,
                detail: "Said by \(Self.joined(names))",
                delta: nil,
                count: names.count,
                isNegative: true
            )
        }
        .sorted { ($0.count ?? 0, $1.title) > ($1.count ?? 0, $0.title) }
    }

    // MARK: - History patterns

    private func patternReasons(forMeal meal: Meal) -> [TableReason] {
        let raters = verdictDetails(forMeal: meal.id).filter { $0.score != nil }
        guard !raters.isEmpty else { return [] }

        var groups: [String: (affinity: RaterTagAffinity, names: [String], weighted: Double, samples: Int)] = [:]
        for rater in raters {
            // verdictDetails calls the viewer "Me"; a sentence about them says "You".
            let name = rater.ref == .account(userID) ? "You" : rater.name
            for affinity in raterExplanation(for: rater.ref, meal: meal) {
                var group = groups[affinity.id] ?? (affinity, [], 0, 0)
                group.names.append(name)
                group.weighted += affinity.delta * Double(affinity.sampleCount)
                group.samples += affinity.sampleCount
                groups[affinity.id] = group
            }
        }

        return groups.values.compactMap { group -> TableReason? in
            guard group.samples > 0 else { return nil }
            let delta = Int((group.weighted / Double(group.samples) * 100).rounded())
            guard delta != 0 else { return nil }
            return TableReason(
                source: .pattern(id: group.affinity.id),
                title: Self.title(for: group.affinity.kind, isNegative: delta < 0),
                detail: Self.detail(for: group.affinity.kind, names: group.names, delta: delta),
                delta: delta,
                count: nil,
                isNegative: delta < 0
            )
        }
        .sorted { abs($0.delta ?? 0) > abs($1.delta ?? 0) }
    }

    private static func title(for kind: RaterTagAffinity.Kind, isNegative: Bool) -> String {
        switch kind {
        case .dishKind(let name), .cookingMethod(let name), .ingredient(let name):
            return name.prefix(1).uppercased() + name.dropFirst()
        case .cuisine(let name):
            return name.capitalized
        case .baseline:
            return isNegative ? "Below the usual" : "Above the usual"
        }
    }

    private static func detail(for kind: RaterTagAffinity.Kind, names: [String], delta: Int) -> String {
        let who = joined(names)
        let direction = delta < 0 ? "lower" : "higher"
        let rate = names == ["You"] || names.count > 1 ? "rate" : "rates"
        switch kind {
        case .dishKind(let name):
            return "\(who) \(rate) \(name.lowercased()) \(direction)"
        case .cookingMethod(let name):
            return "\(who) \(rate) \(name.lowercased()) dishes \(direction)"
        case .ingredient(let name):
            return "\(who) \(rate) dishes with \(name.lowercased()) \(direction)"
        case .cuisine(let name):
            return "\(who) \(rate) \(name.capitalized) food \(direction)"
        case .baseline:
            return "\(who) scored it \(abs(delta)) \(delta < 0 ? "below" : "above") usual"
        }
    }

    /// "Anna", "Anna and Leo", "You, Anna and Leo" (the viewer first).
    static func joined(_ names: [String]) -> String {
        let names = names.filter { $0 == "You" } + names.filter { $0 != "You" }
        guard names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
    }
}
