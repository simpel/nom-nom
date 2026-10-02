import SwiftUI

/// One rater in MealScoreBreakdownSheet: a ListRow with their initials, their top
/// taste insight as meta and their score. Tappable (with a chevron) when there is
/// an explanation to open.
struct MealMemberScoreRow: View {
    let detail: FoodStore.VerdictDetail
    let affinities: [RaterTagAffinity]
    var onTapExplain: (() -> Void)?

    private var canExplain: Bool { !affinities.isEmpty && onTapExplain != nil }

    private var insight: String? {
        guard let top = affinities.first else { return nil }
        let more = affinities.count > 1 ? " \u{00B7} \(affinities.count - 1) more" : ""
        return top.shortSummary + more
    }

    var body: some View {
        // Meta is `sans-sm` secondary (README); the insight's direction is in its words.
        ListRow(
            detail.name,
            meta: insight,
            value: detail.reaction == nil ? "Pending" : nil,
            leading: .avatar(Avatar(name: detail.name, size: .sm)),
            trailing: detail.reaction.map { .score($0.score) },
            action: canExplain ? onTapExplain : nil
        )
    }
}
