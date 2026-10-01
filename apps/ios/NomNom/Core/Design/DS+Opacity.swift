import CoreGraphics

extension DS {
    /// Tailwind opacity scale (`opacity-*` in `tokens.json`).
    enum Opacity {
        static let o0: Double = 0
        static let o5: Double = 0.05
        /// Tinted (featured) card ground.
        static let o10: Double = 0.10
        /// Reaction badge grounds.
        static let o15: Double = 0.15
        /// Selected picker / TasteScoreSelector cell ground.
        static let o20: Double = 0.20
        static let o25: Double = 0.25
        /// Hairlines on cards and fields.
        static let o30: Double = 0.30
        static let o40: Double = 0.40
        /// Disabled buttons and fields.
        static let o50: Double = 0.50
        static let o60: Double = 0.60
        /// Pressed button.
        static let o70: Double = 0.70
        static let o75: Double = 0.75
        /// Focus and error borders.
        static let o80: Double = 0.80
        static let o90: Double = 0.90
        static let o95: Double = 0.95
        static let o100: Double = 1

        // MARK: - Semantic aliases

        static let tint = o10
        static let reactionBadge = o15
        /// ProgressBar track on a featured card (`primary` at 18% over `panel`).
        static let featuredTrack: Double = 0.18
        static let selected = o20
        static let hairline = o30
        static let disabled = o50
        static let pressed = o70
        static let focus = o80
    }
}
