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
            // README "Colour": `reaction-<step>-text` is the ink for its numeral or word;
            // there is no `on-reaction`. bundle.css: `--role-on: var(--nn-text)`.
            return DS.Role(
                fill: reaction.fill,
                soft: reaction.fill.opacity(DS.Opacity.reactionBadge),
                text: reaction.text,
                on: reaction.text
            )
        }
    }

    /// Border colour for the `outline` appearance. README "Colour": "A line that
    /// carries meaning is `line-control`, not `line-strong`. Outline buttons … hold at
    /// least 3:1" — so secondary uses `line-control` (bundle.css `--role-border`),
    /// not the AppButton README's older "`line-strong` for secondary" (DS-GAPS.md).
    var outlineBorder: Color {
        self == .secondary ? DS.Color.lineControl : role.fill
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
    /// Clear ground, `{role}-text` ink, `border-hairline` `{role}` border. Buttons only.
    case outline
    /// `{role}-text` ink only. Buttons only.
    case ghost
    /// `panel` ground + `shadow-xs`, for things floating over content.
    case elevated

    /// Border width of the `outline` appearance: `border-hairline`, as bundle.css
    /// draws it (`--bw: var(--border-hairline)`). The AppButton README's "1.5px" has
    /// no token and README "Scales" names hairline and thick as "the only two widths
    /// the system draws" (DS-GAPS.md).
    static let outlineBorderWidth: CGFloat = DS.BorderWidth.hairline
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
