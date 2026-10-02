import CoreGraphics

extension DS {
    /// Tailwind v4 radius scale, aliased from `DSTokens.Radius`. Corners are continuous.
    /// Names follow the tokens: `radius-2xl` → `xl2`.
    enum Radius {
        private typealias T = DSTokens.Radius
        /// 4pt: grabber, progress track ends.
        static let sm = T.sm
        /// 6pt.
        static let md = T.md
        /// 8pt: compact score boxes, picker cells.
        static let lg = T.lg
        /// 12pt: inputs, recipe thumbnails, photo chips.
        static let xl = T.xl
        /// 16pt: timeline tiles and photos inside a list.
        static let xl2 = T.xl2
        /// 24pt: cards, list cards, hero photos, the score card.
        static let xl3 = T.xl3
        /// 32pt: top corners of a bottom sheet.
        static let xl4 = T.xl4
        /// Capsule: buttons, chips, pills, badges, avatars.
        static let full = T.full
    }
}
