import Foundation

/// A one-line summary of how a dish lands with the household, combining taste,
/// effort and rotation goal (the design system's "Dish summary" badge recipe).
/// Pure domain logic: the view layer maps `role` to colours.
struct DishSummary: Equatable {
    /// The colour role the badge is painted in.
    enum Role: Equatable {
        case primary
        case secondary
        case reaction(Reaction)
    }

    let title: String
    /// SF Symbol name for the badge icon.
    let systemImage: String
    let role: Role

    /// Returns `nil` when there is nothing to say (no ratings and no effort or
    /// rotation signal).
    init?(reactions: [Reaction], effort: EffortLevel? = nil, repeatDesire: RotationGoal? = nil) {
        let total = reactions.count
        let positive = reactions.filter(\.isPositive).count
        let negative = reactions.filter(\.isNegative).count
        let crowdPleasing = total > 0 && negative == 0 && Double(positive) / Double(total) >= 0.6

        if crowdPleasing {
            if effort == .zeroTo15 {
                self.init("Quick win", "bolt.fill", .primary)
            } else if repeatDesire == .staple {
                self.init("Household favorite", "star.fill", .reaction(.amazing))
            } else if effort == .over60 {
                self.init("Showstopper", "sparkles", .primary)
            } else {
                self.init("Crowd pleaser", "hand.thumbsup.fill", .reaction(.great))
            }
            return
        }

        if repeatDesire == .staple {
            self.init("Household staple", "arrow.triangle.2.circlepath", .primary)
        } else if effort == .zeroTo15 {
            self.init("Fast & easy", "bolt.fill", .primary)
        } else if effort == .over60 {
            self.init("Weekend project", "flame.fill", .primary)
        } else if negative > 0 && positive == 0 {
            self.init("Needs revision", "wrench.and.screwdriver.fill", .secondary)
        } else if total > 0 {
            self.init("Solid dish", "checkmark.circle.fill", .primary)
        } else {
            return nil
        }
    }

    private init(_ title: String, _ systemImage: String, _ role: Role) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
    }
}
