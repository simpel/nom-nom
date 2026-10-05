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

/// README "Motion and states": "Press: `opacity-70` over 120ms ease-out. Buttons never
/// scale" (`duration-press`, `ease-standard`). AppButton README: "a button never changes
/// size on press."
struct AppPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? DS.Opacity.pressed : DS.Opacity.o100)
            .animation(DS.Motion.press, value: configuration.isPressed)
    }
}
