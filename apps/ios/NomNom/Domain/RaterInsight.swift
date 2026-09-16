import Foundation

/// How strongly a rater's scores for dishes carrying a given tag/ingredient deviate from
/// their own overall average — the basis for "why did they score it that way" explanations.
struct RaterTagAffinity: Identifiable, Hashable {
    var id: String { tag }
    let tag: String
    let raterAverage: Double
    let raterOverallAverage: Double
    let sampleCount: Int

    var delta: Double { raterAverage - raterOverallAverage }

    func sentence(name: String) -> String {
        let direction = delta < 0 ? "lower" : "higher"
        return "\(name) tends to rate \(tag) dishes \(direction) " +
               "(avg \(Int((raterAverage * 100).rounded())) vs \(Int((raterOverallAverage * 100).rounded())) overall)"
    }
}
