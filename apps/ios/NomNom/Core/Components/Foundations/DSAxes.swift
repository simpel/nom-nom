import SwiftUI

// The axes every design-system component shares: a colour role (`variant`),
// a visual weight (`appearance`) and where an icon sits (`iconPosition`).

/// The colour role a component is painted in.
enum DSVariant: Equatable {
    case primary
    case secondary
    case destructive
    /// Nom Nom Pro only.
    case pro
    /// Negative change only, never errors.
    case warning
    /// A rating step. Only inside rating data and rating controls.
    case reaction(Reaction)

    /// The four role tokens the appearance paints with.
    var role: DS.Role {
        switch self {
        case .primary: return .primary
        case .secondary: return .secondary
        case .destructive: return .destructive
        case .pro: return .pro
        case .warning: return .warning
        case .reaction(let reaction):
            return DS.Role(
                fill: reaction.fill,
                soft: reaction.fill.opacity(DS.Opacity.reactionBadge),
                text: reaction.text,
                on: DS.Color.onPrimary
            )
        }
    }

    /// Border colour for the `outline` appearance (`line-strong` for secondary).
    var outlineBorder: Color {
        self == .secondary ? DS.Color.lineStrong : role.fill
    }

    var isReaction: Bool {
        if case .reaction = self { return true }
        return false
    }
}

/// The visual weight of a component.
enum DSAppearance: Equatable {
    /// `{role}` ground + `on-{role}` ink.
    case solid
    /// `{role}-soft` ground + `{role}-text` ink.
    case soft
    /// Clear ground, `{role}-text` ink, 1.5pt `{role}` border. Buttons only.
    case outline
    /// `{role}-text` ink only. Buttons only.
    case ghost
    /// `panel` ground + `shadow-xs`, for things floating over content.
    case elevated

    /// Border width of the `outline` appearance.
    static let outlineWidth: CGFloat = 1.5
}

/// Which side of the label an icon sits on.
enum DSIconPosition: Equatable {
    case start
    case end
}

/// Ground, ink and border resolved from a variant and an appearance.
struct DSPaint {
    let background: Color
    let foreground: Color
    let border: Color?
    let isElevated: Bool

    /// Button painting. `elevated` inks in `text-primary`.
    init(variant: DSVariant, appearance: DSAppearance) {
        let role = variant.role
        switch appearance {
        case .solid:
            self.init(background: role.fill, foreground: role.on, border: nil, isElevated: false)
        case .soft:
            self.init(background: role.soft, foreground: role.text, border: nil, isElevated: false)
        case .outline:
            self.init(background: .clear, foreground: role.text, border: variant.outlineBorder, isElevated: false)
        case .ghost:
            self.init(background: .clear, foreground: role.text, border: nil, isElevated: false)
        case .elevated:
            self.init(background: DS.Color.panel, foreground: DS.Color.textPrimary, border: nil, isElevated: true)
        }
    }

    init(background: Color, foreground: Color, border: Color?, isElevated: Bool) {
        self.background = background
        self.foreground = foreground
        self.border = border
        self.isElevated = isElevated
    }
}
