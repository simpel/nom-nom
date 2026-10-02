import SwiftUI

/// How a text field (Input, TextArea) is painted.
enum InputAppearance: Equatable {
    /// `sunken` ground + 0.5pt `line` at 30%. The default.
    case soft
    /// Clear ground + 0.5pt `line-strong`.
    case outline
    /// No ground, border or side padding: the row supplies them.
    case plain
}

/// Shared field metrics and state colours for Input and TextArea.
enum InputMetrics {
    static let height = DS.Spacing.s11
    static let labeledHeight = DS.Spacing.s14
    static let radius = DS.Radius.xl
    static let sidePadding = DS.Spacing.s3_5
    static let restingWidth: CGFloat = 0.5
    static let activeWidth = DSAppearance.outlineWidth
    static let animation = Animation.easeOut(duration: 0.15)

    static var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    static func background(_ appearance: InputAppearance) -> Color {
        appearance == .soft ? DS.Color.sunken : .clear
    }

    /// Border colour, or nil for none. Error beats focus; `plain` has no border.
    static func border(_ appearance: InputAppearance, focused: Bool, error: Bool) -> Color? {
        guard appearance != .plain else { return nil }
        if error { return DS.Color.destructive }
        if focused { return DS.Color.primary }
        return appearance == .soft ? DS.Color.line.opacity(DS.Opacity.hairline) : DS.Color.lineStrong
    }

    static func borderWidth(focused: Bool, error: Bool) -> CGFloat {
        focused || error ? activeWidth : restingWidth
    }
}

// MARK: - Legacy (pre-design-system field API)

/// Pre-design-system field sizes. Every field is now one height (44, or 56 with a label).
enum AppInputSize {
    case sm
    case md
    case xl
}

/// Pre-design-system field styles; see `appearance` for the mapping.
enum AppInputStyle {
    case filled
    case cardRow
    case outlined
    case plain

    /// `.filled` → soft, `.outlined` → outline, `.cardRow`/`.plain` → plain.
    var appearance: InputAppearance {
        switch self {
        case .filled: return .soft
        case .outlined: return .outline
        case .cardRow, .plain: return .plain
        }
    }
}

/// Pre-design-system field shape. Ignored: every field is `radius-xl`.
enum AppInputShape: Equatable {
    case rounded(CGFloat = DS.Radius.xl)
    case capsule
}

/// Leading or trailing icon: a system symbol, an asset or an image.
enum AppInputIcon: ExpressibleByStringLiteral {
    case system(String)
    case asset(String)
    case image(Image)

    init(stringLiteral value: String) {
        self = .system(value)
    }
}
