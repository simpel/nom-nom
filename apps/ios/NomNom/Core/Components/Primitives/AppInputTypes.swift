import SwiftUI

/// How a text field (Input, TextArea) is painted. There is one style, `soft`.
enum InputAppearance: Equatable {
    /// `sunken` ground + 1pt `line-control` border. The default, everywhere.
    case soft
    /// No ground, border or side padding: only inside a `Card(layout: .list)` row,
    /// where the row already draws all three.
    case plain
}

/// The state a field draws. The ground never changes: the border carries every state.
/// Loudest wins: disabled, then read-only, then error, then focus.
enum InputState: Equatable {
    case rest, focused, error, readOnly, disabled

    init(focused: Bool, error: Bool, readOnly: Bool, disabled: Bool) {
        if disabled {
            self = .disabled
        } else if readOnly {
            self = .readOnly
        } else if error {
            self = .error
        } else if focused {
            self = .focused
        } else {
            self = .rest
        }
    }
}

/// Shared field metrics and state colours for Input and TextArea
/// (`components/Input/README.md`, "Shape" and "States").
enum InputMetrics {
    static let height = DS.Spacing.s11
    static let labeledHeight = DS.Spacing.s14
    static let radius = DS.Radius.xl
    static let sidePadding = DS.Spacing.s3_5
    /// TextArea top padding, so its first line sits where an Input's text does.
    static let textAreaTopPadding = DS.Spacing.s2_5
    /// Field to hint / error message (bundle.css `.nn-field-block`).
    static let messageSpacing = DS.Spacing.s1_5
    /// "Transitions are 0.15s ease-out on the border only."
    static var animation: Animation { DS.Motion.state }

    static var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    static func background(_ appearance: InputAppearance) -> Color {
        appearance == .soft ? DS.Color.sunken : .clear
    }

    /// Border colour and width, or nil for none (`plain`, read-only).
    static func border(_ appearance: InputAppearance, state: InputState) -> (color: Color, width: CGFloat)? {
        guard appearance != .plain else { return nil }
        switch state {
        case .rest: return (DS.Color.lineControl, DS.BorderWidth.hairline)
        case .focused: return (DS.Color.primary, DS.BorderWidth.thick)
        case .error: return (DS.Color.destructive, DS.BorderWidth.thick)
        case .readOnly: return nil
        case .disabled: return (DS.Color.line, DS.BorderWidth.hairline)
        }
    }

    static func text(_ state: InputState) -> Color {
        switch state {
        case .readOnly: return DS.Color.textSecondary
        case .disabled: return DS.Color.textTertiary
        default: return DS.Color.textPrimary
        }
    }

    static func label(_ state: InputState) -> Color {
        switch state {
        case .focused: return DS.Color.primaryText
        case .error: return DS.Color.destructiveText
        case .disabled: return DS.Color.textTertiary
        default: return DS.Color.textSecondary
        }
    }

    /// Only the leading icon turns `primary` on focus.
    static func icon(_ state: InputState, leading: Bool) -> Color {
        switch state {
        case .focused where leading: return DS.Color.primary
        case .error: return DS.Color.destructiveText
        case .disabled: return DS.Color.textTertiary
        default: return DS.Color.textSecondary
        }
    }
}

/// Ground, border and shape of a field; the border animates with `DS.Motion.state`.
struct InputChrome: ViewModifier {
    let appearance: InputAppearance
    let state: InputState

    func body(content: Content) -> some View {
        content
            .background(InputMetrics.background(appearance), in: InputMetrics.shape)
            .overlay {
                if let border = InputMetrics.border(appearance, state: state) {
                    InputMetrics.shape.strokeBorder(border.color, lineWidth: border.width)
                }
            }
            .contentShape(InputMetrics.shape)
            .animation(InputMetrics.animation, value: state)
    }
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
