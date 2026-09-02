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
        let tint: Color
    }

    private var badge: BadgeData? {
        let positiveCount = reactions.filter(\.isPositive).count
        let negativeCount = reactions.filter(\.isNegative).count
        let total = reactions.count

        if total > 0 && negativeCount == 0 && (Double(positiveCount) / Double(total) >= 0.6) {
            if effort == .zeroTo15 {
                return BadgeData(title: "Quick Win", systemImage: "bolt.fill", tint: .cyan)
            }
            if repeatDesire == .staple {
                return BadgeData(title: "Household Favorite", systemImage: "star.fill", tint: .yellow)
            }
            if effort == .over60 {
                return BadgeData(title: "Showstopper", systemImage: "sparkles", tint: .purple)
            }
            return BadgeData(title: "Crowd Pleaser", systemImage: "hand.thumbsup.fill", tint: .green)
        }

        if repeatDesire == .staple {
            return BadgeData(title: "Household Staple", systemImage: "arrow.triangle.2.circlepath", tint: .emeraldGreen)
        }

        if effort == .zeroTo15 {
            return BadgeData(title: "Fast & Easy", systemImage: "bolt.fill", tint: .cyan)
        }

        if effort == .over60 {
            return BadgeData(title: "Weekend Project", systemImage: "flame.fill", tint: .orange)
        }

        if negativeCount > 0 && positiveCount == 0 {
            return BadgeData(title: "Needs Revision", systemImage: "wrench.and.screwdriver.fill", tint: .secondary)
        }

        if total > 0 {
            return BadgeData(title: "Solid Dish", systemImage: "checkmark.circle.fill", tint: .blue)
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
            .foregroundStyle(badge.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(badge.tint.opacity(0.14))
            }
            .overlay {
                Capsule()
                    .strokeBorder(badge.tint.opacity(0.3), lineWidth: 1)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}

typealias DishVerdictBadge = RecipeVerdictBadge

private extension Color {
    static let emeraldGreen = Color(red: 0.18, green: 0.72, blue: 0.44)
}
