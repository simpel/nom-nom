import SwiftUI

extension DS {
    /// Border and ring widths (`border-*`), aliased from `DSTokens.BorderWidth`.
    /// The only widths the system draws.
    enum BorderWidth {
        /// 1pt: dividers, card hairlines, a field at rest.
        static let hairline = DSTokens.BorderWidth.hairline
        /// 2pt: focus ring, error border, selected ring.
        static let thick = DSTokens.BorderWidth.thick
    }

    /// Durations, easing and press scales (`motion`), aliased from `DSTokens.Motion`.
    enum Motion {
        private typealias T = DSTokens.Motion
        static let durationPress = T.durationPress
        static let durationState = T.durationState
        static let durationLayout = T.durationLayout
        static let scalePress = T.scalePress
        static let scalePressRow = T.scalePressRow
        static let scaleKnob = T.scaleKnob

        /// `ease-standard` (`ease-out`, the one easing curve) over a duration token.
        static func standard(_ duration: Double) -> Animation {
            switch T.easeStandard {
            case "ease-out": return .easeOut(duration: duration)
            case "ease-in": return .easeIn(duration: duration)
            case "ease-in-out": return .easeInOut(duration: duration)
            default: return .linear(duration: duration)
            }
        }

        static var press: Animation { standard(durationPress) }
        static var state: Animation { standard(durationState) }
        static var layout: Animation { standard(durationLayout) }
    }

    /// Letter spacing (`tracking-*`), in em; multiply by the font size for points.
    enum Tracking {
        /// −0.025em: large serif display.
        static let tight = DSTokens.Tracking.tight
        /// 0.1em: uppercase overlines (section headers, eyebrows).
        static let widest = DSTokens.Tracking.widest
    }
}
