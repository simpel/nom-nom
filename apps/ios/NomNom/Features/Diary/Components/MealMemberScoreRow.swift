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

    private var insightColor: Color? {
        guard let top = affinities.first else { return nil }
        return top.delta < 0 ? DS.Color.warningText : DS.Color.primaryText
    }

    var body: some View {
        if canExplain {
            ListRow(
                detail.name,
                meta: insight,
                metaColor: insightColor,
                leading: .avatar(Avatar(name: detail.name, size: .sm)),
                trailing: scoreSlot, .chevron,
                action: onTapExplain
            )
        } else {
            ListRow(
                detail.name,
                meta: insight,
                metaColor: insightColor,
                leading: .avatar(Avatar(name: detail.name, size: .sm)),
                trailing: scoreSlot
            )
        }
    }

    private var scoreSlot: ListRowTrailing {
        if let reaction = detail.reaction { return .score(reaction.score) }
        return .value("Pending")
    }
}
