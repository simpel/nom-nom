import Foundation

/// How strongly a rater's scores for dishes carrying a given dish kind, ingredient,
/// cuisine, or general baseline deviate from their overall average — the basis for
/// "why did they score it that way" explanations on meals and taste preferences on profiles.
struct RaterTagAffinity: Identifiable, Hashable {
    enum Kind: Hashable {
        case dishKind(name: String)
        case cookingMethod(name: String)
        case ingredient(name: String)
        case cuisine(name: String)
        case baseline
    }

    var id: String { "\(kindID)_\(tag)" }

    private var kindID: String {
        switch kind {
        case .dishKind: return "kind"
        case .cookingMethod: return "meth"
        case .ingredient: return "ing"
        case .cuisine: return "cui"
        case .baseline: return "base"
        }
    }

    let kind: Kind
    let tag: String
    let raterAverage: Double
    let raterOverallAverage: Double
    let sampleCount: Int

    var delta: Double { raterAverage - raterOverallAverage }

    init(
        kind: Kind = .ingredient(name: ""),
        tag: String,
        raterAverage: Double,
        raterOverallAverage: Double,
        sampleCount: Int
    ) {
        self.kind = kind
        self.tag = tag
        self.raterAverage = raterAverage
        self.raterOverallAverage = raterOverallAverage
        self.sampleCount = sampleCount
    }

    /// Short inline pill/badge, e.g. "Rates stews lower", "Likes cilantro", "-35 vs avg".
    var shortSummary: String {
        let direction = delta < 0 ? "lower" : "higher"
        switch kind {
        case .dishKind(let name):
            return "Rates \(name.lowercased()) \(direction)"
        case .cookingMethod(let name):
            return "Rates \(name.lowercased()) \(direction)"
        case .ingredient(let name):
            return delta < 0 ? "Dislikes \(name.lowercased())" : "Likes \(name.lowercased())"
        case .cuisine(let name):
            return "Rates \(name) \(direction)"
        case .baseline:
            let pts = Int(abs(delta * 100).rounded())
            return delta < 0 ? "-\(pts) vs their avg" : "+\(pts) vs their avg"
        }
    }

    func sentence(name: String) -> String {
        let direction = delta < 0 ? "lower" : "higher"
        let avgScore = Int((raterAverage * 100).rounded())
        let overallAvg = Int((raterOverallAverage * 100).rounded())
        let sampleText = sampleCount == 1 ? "1 past occasion" : "\(sampleCount) past occasions"

        switch kind {
        case .dishKind(let kindName):
            return "\(name) tends to rate \(kindName.lowercased()) dishes \(direction) " +
                   "(avg \(avgScore) vs \(overallAvg) overall across \(sampleText))."
        case .cookingMethod(let methodName):
            return "\(name) tends to rate \(methodName.lowercased()) dishes \(direction) " +
                   "(avg \(avgScore) vs \(overallAvg) overall across \(sampleText))."
        case .ingredient(let ingredientName):
            return "\(name) tends to rate dishes with \(ingredientName.lowercased()) \(direction) " +
                   "(avg \(avgScore) vs \(overallAvg) overall across \(sampleText))."
        case .cuisine(let cuisineName):
            return "\(name) tends to rate \(cuisineName.capitalized) cuisine \(direction) " +
                   "(avg \(avgScore) vs \(overallAvg) overall across \(sampleText))."
        case .baseline:
            let pts = Int(abs(delta * 100).rounded())
            let relation = delta < 0 ? "\(pts) points below" : "\(pts) points above"
            return "\(name) rated this \(relation) their historical average of \(overallAvg)."
        }
    }
}
