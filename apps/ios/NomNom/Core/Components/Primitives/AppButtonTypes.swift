import SwiftUI

/// Button sizes (AppButton README table): height, side padding, label step and gap.
///
/// "No button is smaller than 44 × 44": `xs`, `sm` and `md` are all `spacing-11`
/// tall and differ only in type and side padding; `lg` is `spacing-12`. Heights are
/// minimums, so the capsule grows with Dynamic Type instead of clipping.
enum AppButtonSize: Equatable, CaseIterable {
    case xs
    case sm
    case md
    case lg

    @available(*, deprecated, renamed: "lg")
    static var xl: AppButtonSize { .lg }

    /// Minimum height of a labelled button.
    var height: CGFloat {
        switch self {
        case .xs, .sm, .md: return DS.Spacing.s11
        case .lg: return DS.Spacing.s12
        }
    }

    /// The floor on every button's width and height (`min-width` / `min-height`).
    static let minimumTarget: CGFloat = DS.Spacing.s11

    /// "Icon-only, all four sizes are the same 44 × 44 circle."
    static let iconOnlyDiameter: CGFloat = DS.Spacing.s11

    var horizontalPadding: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s2_5
        case .sm: return DS.Spacing.s3
        case .md: return DS.Spacing.s4
        case .lg: return DS.Spacing.s5
        }
    }

    /// Label step (always set semibold); the icon is the same `text-*` size.
    var textStyle: DS.TextStyle {
        switch self {
        case .xs: return .sansXs
        case .sm: return .sansSm
        case .md: return .sansMd
        case .lg: return .sansLg
        }
    }

    var gap: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s1
        case .sm: return DS.Spacing.s1_5
        case .md, .lg: return DS.Spacing.s2
        }
    }

    var iconSize: CGFloat { textStyle.size }

    var spinnerSize: ControlSize {
        switch self {
        case .xs, .sm: return .mini
        case .md, .lg: return .small
        }
    }
}

/// Icon representation supporting system SF Symbols, named assets, or custom SwiftUI Images.
enum AppButtonIcon: ExpressibleByStringLiteral {
    case system(String)
    case asset(String)
    case image(Image)
    /// A short glyph set as text (tabular), e.g. the TasteScoreSelector numerals.
    case text(String)

    init(stringLiteral value: String) {
        self = .system(value)
    }
}

/// README "Motion and states": "Press: `opacity-70` and scale 0.985 over 120ms
/// ease-out" (`scale-press`, `duration-press`, `ease-standard`). Reduce Motion keeps
/// the fade and drops the scale ("it also removes press transforms").
struct AppPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AppPressEffect(label: configuration.label, isPressed: configuration.isPressed)
    }
}

private struct AppPressEffect<Label: View>: View {
    let label: Label
    let isPressed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        label
            .opacity(isPressed ? DS.Opacity.pressed : DS.Opacity.o100)
            .scaleEffect(isPressed && !reduceMotion ? DS.Motion.scalePress : 1)
            .animation(DS.Motion.press, value: isPressed)
    }
}

// MARK: - Legacy axes (pre-design-system AppButton API)

/// Legacy button intent. Maps onto `DSVariant` + `DSAppearance` via `dsAxes(style:)`.
enum AppButtonVariant {
    case primary
    case secondary
    case neutral
    case destructive
    case pro
}

/// Legacy visual weight: `.normal` / `.outlined` / `.ghost`.
enum AppButtonStyle {
    case normal
    case outlined
    case ghost
}

/// Legacy icon position: `.leading` / `.trailing`.
enum AppButtonIconPosition {
    case leading
    case trailing

    var dsPosition: DSIconPosition { self == .trailing ? .end : .start }
}

extension AppButtonVariant {
    /// AppButton README "Migration": `.primary` → primary solid, `.secondary` →
    /// primary soft, `.neutral` → secondary, `.destructive` → destructive, `.pro` →
    /// pro; style `.outlined` → outline, `.ghost` → ghost.
    func dsAxes(style: AppButtonStyle) -> (DSVariant, DSAppearance) {
        let variant: DSVariant
        let filled: DSAppearance
        switch self {
        case .primary: variant = .primary; filled = .solid
        case .secondary: variant = .primary; filled = .soft
        case .neutral: variant = .secondary; filled = .soft
        case .destructive: variant = .destructive; filled = .solid
        case .pro: variant = .pro; filled = .solid
        }
        switch style {
        case .normal: return (variant, filled)
        case .outlined: return (variant, .outline)
        case .ghost: return (variant, .ghost)
        }
    }
}
