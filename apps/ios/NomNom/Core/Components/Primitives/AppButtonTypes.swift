import SwiftUI

/// Button sizes (AppButton README): height, side padding, label step and icon gap.
enum AppButtonSize: Equatable {
    case sm
    case md
    case lg

    @available(*, deprecated, renamed: "lg")
    static var xl: AppButtonSize { .lg }

    var height: CGFloat {
        switch self {
        case .sm: return DS.Spacing.s9
        case .md: return DS.Spacing.s11
        case .lg: return DS.Spacing.s12
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm: return DS.Spacing.s3
        case .md: return DS.Spacing.s4
        case .lg: return DS.Spacing.s5
        }
    }

    /// Label step; icons use the same step so glyph and text match.
    var textStyle: DS.TextStyle {
        switch self {
        case .sm: return .sansSm
        case .md: return .sansMd
        case .lg: return .sansLg
        }
    }

    var gap: CGFloat {
        switch self {
        case .sm: return DS.Spacing.s1_5
        case .md, .lg: return DS.Spacing.s2
        }
    }

    var iconSize: CGFloat { textStyle.size }

    var spinnerSize: ControlSize { self == .sm ? .mini : .small }
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

/// Opacity 0.7 + scale 0.985 on press, 120ms ease-out.
struct AppPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? DS.Opacity.pressed : DS.Opacity.o100)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Legacy axes (pre-design-system AppButton API)

/// Legacy button intent. Maps onto `DSVariant` + `DSAppearance` via `AppButton.legacyAxes`.
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
    /// The design-system variant and appearance a legacy variant/style pair becomes:
    /// `.primary` → primary solid, `.secondary` → primary soft, `.neutral` → secondary
    /// (soft), `.destructive` → destructive, `.pro` → pro; `.outlined` → outline,
    /// `.ghost` → ghost.
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
