import Foundation

/// The Badge README recipes: what the old badges become.
extension Badge {
    /// Verdict for a normalised 0–1 score: the reaction colour and its word only
    /// (never the number); the 0–100 score rides along as the tooltip.
    static func verdict(score: Double, appearance: BadgeAppearance = .soft, size: BadgeSize = .md) -> Badge {
        let reaction = Reaction(score: score)
        return Badge(
            reaction.shortLabel, variant: .reaction(reaction), appearance: appearance, size: size,
            tooltip: (score * 100).rounded().formatted(.number.precision(.fractionLength(0)))
        )
    }

    /// Verdict for a reaction step: the reaction colour and its word only.
    static func verdict(_ reaction: Reaction, appearance: BadgeAppearance = .soft, size: BadgeSize = .md) -> Badge {
        Badge(reaction.shortLabel, variant: .reaction(reaction), appearance: appearance, size: size)
    }

    /// Change since last time as a signed number with a true minus:
    /// up `primary` ("+16"), down `warning` ("−2"), flat `secondary` ("±0").
    static func delta(_ value: Int, size: BadgeSize = .md) -> Badge {
        if value > 0 {
            return Badge("+\(value)", variant: .primary, size: size, accessibilityLabel: "Up \(value)")
        } else if value < 0 {
            return Badge("\u{2212}\(-value)", variant: .warning, size: size, accessibilityLabel: "Down \(-value)")
        }
        return Badge("\u{00B1}0", variant: .secondary, size: size, accessibilityLabel: "No change")
    }

    /// Rotation goal, `sm`; the order reads as weight. Staple carries the repeat icon.
    static func rotation(_ goal: RotationGoal) -> Badge {
        switch goal {
        case .oneAndDone:
            return Badge("One & done", variant: .secondary, size: .sm)
        case .sometimes:
            return Badge("Sometimes", variant: .primary, size: .sm)
        case .staple:
            return Badge("Staple", icon: "repeat", variant: .primary, appearance: .solid, size: .sm)
        }
    }

    /// Nom Nom Pro.
    static var pro: Badge {
        Badge("Pro", icon: "sparkles", variant: .pro)
    }

    /// The one-line dish summary ("Quick win", "Crowd pleaser", …).
    static func dishSummary(_ summary: DishSummary, size: BadgeSize = .md) -> Badge {
        let variant: DSVariant
        switch summary.role {
        case .primary: variant = .primary
        case .secondary: variant = .secondary
        case .reaction(let reaction): variant = .reaction(reaction)
        }
        return Badge(summary.title, icon: summary.systemImage, variant: variant, size: size)
    }

    /// Leaderboard rank: `secondary sm`, star icon + ordinal ("3rd").
    static func rank(_ position: Int) -> Badge {
        let ordinal = ordinalFormatter.string(from: NSNumber(value: position)) ?? "\(position)"
        return Badge(ordinal, icon: "star.fill", variant: .secondary, size: .sm, accessibilityLabel: "Rank \(ordinal)")
    }

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
}
