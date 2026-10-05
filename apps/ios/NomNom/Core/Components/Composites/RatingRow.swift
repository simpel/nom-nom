import SwiftUI

/// The trailing action on an unrated RatingList row, an AppButton `sm`.
enum RatingListAction {
    /// The viewer hasn't rated: `primary soft` "Rate".
    case rate(() -> Void)
    /// Someone hasn't rated and can be asked: `secondary soft` "Ask to rate".
    case ask(isLoading: Bool = false, () -> Void)
    /// Already asked: a disabled `secondary ghost` "Asked".
    case asked
}

/// One person in a RatingList.
struct RatingListEntry: Identifiable {
    let id: AnyHashable
    var name: String
    /// A short role after the name, e.g. "chef".
    var role: String?
    /// Normalised 0–1 (domain scale), or nil when unrated.
    var score: Double?
    /// Change vs their usual score in display points (0–100 scale); 0 reads "As usual".
    var delta: Int?
    /// Their first rating: a `secondary` "New" Badge instead of a delta.
    var isNew: Bool = false
    /// The viewer's own row ("You"); sorted last by RatingList.
    var isViewer: Bool = false
    /// Shown instead of the score (unrated rows: Rate / Ask / Asked).
    var action: RatingListAction?
    /// Tapping the row (e.g. "why this score", or re-rate your own).
    var onTap: (() -> Void)?
}

/// A RatingList row: a ListRow (RatingList README: "Rows are ListRows"). Title: name
/// `sans-md` + role `sans-sm` `text-tertiary`. Trailing: the change vs their usual
/// (delta Badge `sm`, a `secondary` "New" Badge, or "As usual" / "Not rated yet" in
/// `text-tertiary`) and ScoreValue `xs` right-aligned in `spacing-9`. No avatar, no chevron.
struct RatingRow: View {
    let entry: RatingListEntry

    private var name: String { entry.isViewer ? "You" : entry.name }

    var body: some View {
        // README: "the note and the score share its `trailing` slot".
        ListRow(
            accessibilityTitle: name,
            trailing: .view {
                HStack(spacing: DS.Spacing.s2) {
                    change
                    trailing
                }
            },
            chevron: false,
            action: entry.onTap
        ) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s1_5) {
                Text(name).textStyle(.sansMd)
                if let role = entry.role {
                    Text(role).textStyle(.sansSm, tone: .tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var change: some View {
        if entry.score == nil {
            if entry.action == nil {
                Text("Not rated yet").textStyle(.sansSm, tone: .tertiary)
            }
        } else if entry.isNew {
            Badge("New", variant: .secondary, size: .sm)
        } else if let delta = entry.delta {
            if delta == 0 {
                Text("As usual").textStyle(.sansSm, tone: .tertiary)
            } else {
                Badge.delta(delta, size: .sm)
            }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if let score = entry.score {
            ScoreValue(score: score, size: .xs)
                .frame(minWidth: DS.Spacing.s9, alignment: .trailing)
        } else if let action = entry.action {
            switch action {
            case .rate(let perform):
                AppButton("Rate", appearance: .soft, size: .sm, action: perform)
            case .ask(let isLoading, let perform):
                AppButton("Ask to rate", variant: .secondary, appearance: .soft, size: .sm, isLoading: isLoading, action: perform)
            case .asked:
                AppButton("Asked", variant: .secondary, appearance: .ghost, size: .sm) {}
                    .disabled(true)
            }
        }
    }
}
