import SwiftUI

/// Computed dynamic verdict badge for a recipe/meal based on taste, effort, and rotation goals.
struct RecipeVerdictBadge: View {
    let reactions: [Reaction]
    let effort: EffortLevel?
    let repeatDesire: RotationGoal?

    init(reactions: [Reaction], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.reactions = reactions
        self.effort = effort
        self.repeatDesire = repeatDesire
    }

    init(verdicts: [RaterRef: Reaction], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.reactions = Array(verdicts.values)
        self.effort = effort
        self.repeatDesire = repeatDesire
    }

    init(ratings: [MealRating], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        self.reactions = ratings.map(\.reaction)
        self.effort = effort
        self.repeatDesire = repeatDesire
    }

    private var summary: DishSummary? {
        DishSummary(reactions: reactions, effort: effort, repeatDesire: repeatDesire)
    }

    private func colors(for role: DishSummary.Role) -> (fill: Color, text: Color) {
        switch role {
        case .primary: return (DS.Role.primary.fill, DS.Role.primary.text)
        case .secondary: return (DS.Color.lineStrong, DS.Role.secondary.text)
        case .reaction(let reaction): return (reaction.fill, reaction.text)
        }
    }

    var body: some View {
        if let summary {
            let palette = colors(for: summary.role)
            HStack(spacing: 5) {
                Image(systemName: summary.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(summary.title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(palette.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(palette.fill.opacity(0.14))
            }
            .overlay {
                Capsule()
                    .strokeBorder(palette.fill.opacity(0.3), lineWidth: 1)
            }
            .accessibilityLabel(summary.title)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

typealias DishVerdictBadge = RecipeVerdictBadge

