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

    struct BadgeData {
        let title: String
        let systemImage: String
        let fill: Color
        let text: Color
    }

    private var badge: BadgeData? {
        let positiveCount = reactions.filter(\.isPositive).count
        let negativeCount = reactions.filter(\.isNegative).count
        let total = reactions.count

        if total > 0 && negativeCount == 0 && (Double(positiveCount) / Double(total) >= 0.6) {
            if effort == .zeroTo15 {
                return BadgeData(title: "Quick Win", systemImage: "bolt.fill", fill: DS.Color.accent, text: DS.Color.accentText)
            }
            if repeatDesire == .staple {
                return BadgeData(title: "Household Favorite", systemImage: "star.fill", fill: Reaction.amazing.fill, text: Reaction.amazing.text)
            }
            if effort == .over60 {
                return BadgeData(title: "Showstopper", systemImage: "sparkles", fill: DS.Color.accent, text: DS.Color.accentText)
            }
            return BadgeData(title: "Crowd Pleaser", systemImage: "hand.thumbsup.fill", fill: Reaction.great.fill, text: Reaction.great.text)
        }

        if repeatDesire == .staple {
            return BadgeData(title: "Household Staple", systemImage: "arrow.triangle.2.circlepath", fill: DS.Color.accent, text: DS.Color.accentText)
        }

        if effort == .zeroTo15 {
            return BadgeData(title: "Fast & Easy", systemImage: "bolt.fill", fill: DS.Color.accent, text: DS.Color.accentText)
        }

        if effort == .over60 {
            return BadgeData(title: "Weekend Project", systemImage: "flame.fill", fill: DS.Color.accent, text: DS.Color.accentText)
        }

        if negativeCount > 0 && positiveCount == 0 {
            return BadgeData(title: "Needs Revision", systemImage: "wrench.and.screwdriver.fill", fill: DS.Color.lineStrong, text: DS.Color.textSecondary)
        }

        if total > 0 {
            return BadgeData(title: "Solid Dish", systemImage: "checkmark.circle.fill", fill: DS.Color.accent, text: DS.Color.accentText)
        }

        return nil
    }

    var body: some View {
        if let badge {
            HStack(spacing: 5) {
                Image(systemName: badge.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(badge.title.uppercased())
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(badge.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(badge.fill.opacity(0.14))
            }
            .overlay {
                Capsule()
                    .strokeBorder(badge.fill.opacity(0.3), lineWidth: 1)
            }
            .accessibilityLabel(badge.title)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

typealias DishVerdictBadge = RecipeVerdictBadge

