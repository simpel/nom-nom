import Foundation

/// Which rater sheet a Who rated row opens.
struct MealRaterTarget: Identifiable, Hashable {
    let ref: RaterRef
    /// They have rated: RaterScoreSheet; otherwise RaterPendingSheet.
    let hasRated: Bool

    var id: RaterRef { ref }
}
