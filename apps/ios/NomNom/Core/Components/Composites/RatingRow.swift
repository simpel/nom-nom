import SwiftUI

/// The trailing action on a RatingList row, an AppButton `sm`.
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
    /// Avatar photo, shown only when the list has `showsAvatars`.
    var photoPath: String?
    /// Shown instead of the score (unrated rows: Rate / Ask / Asked).
    var action: RatingListAction?
    /// Tapping the row (e.g. "why this score", or re-rate your own).
    var onTap: (() -> Void)?
}

/// A RatingList row: min `s14`; name `sans-md` + role `sans-sm` tertiary, then the change
/// vs usual, then ScoreValue `xs` right-aligned in `s9` (or the trailing AppButton `sm`).
struct RatingRow: View {
    let entry: RatingListEntry
    var showsAvatar: Bool = false

    var body: some View {
        if let onTap = entry.onTap {
            Button(action: onTap) { content }
                .buttonStyle(AppPressableButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: DS.Spacing.s3) {
            if showsAvatar {
                Avatar(name: entry.name, photoPath: entry.photoPath, size: .xs)
            }
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s1_5) {
                Text(entry.isViewer ? "You" : entry.name).textStyle(.sansMd)
                if let role = entry.role {
                    Text(role).textStyle(.sansSm, tone: .tertiary)
                }
            }
            .lineLimit(1)

            Spacer(minLength: DS.Spacing.s2)

            change
            trailing
        }
        .frame(minHeight: DS.Spacing.rowMin)
        .contentShape(Rectangle())
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
                .frame(width: DS.Spacing.s9, alignment: .trailing)
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
