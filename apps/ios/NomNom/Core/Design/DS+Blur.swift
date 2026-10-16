import CoreGraphics

extension DS {
    /// Blur radii for content that is locked, aliased from `DSTokens.Blur`. Never decoration.
    enum Blur {
        /// A locked ProCard's blurred preview.
        static let sm = DSTokens.Blur.sm
        /// A ProGate's blurred view behind its panel.
        static let md = DSTokens.Blur.md
    }

    /// The one dash length for every dashed stroke, on and off (`dash`).
    enum Dash {
        static let length = DSTokens.Dash.dash
    }
}
