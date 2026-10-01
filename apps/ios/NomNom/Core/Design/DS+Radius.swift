import CoreGraphics

extension DS {
    /// Tailwind v4 radius scale (`radius-*` in `tokens.json`). Corners are continuous.
    enum Radius {
        /// 4pt: grabber, progress track ends.
        static let sm: CGFloat = 4
        /// 8pt: compact score boxes, picker cells.
        static let lg: CGFloat = 8
        /// 12pt: inputs, recipe thumbnails, photo chips.
        static let xl: CGFloat = 12
        /// 16pt: timeline tiles and photos inside a list.
        static let xl2: CGFloat = 16
        /// 24pt: cards, list cards, hero photos, the score card.
        static let xl3: CGFloat = 24
        /// 32pt: top corners of a bottom sheet.
        static let xl4: CGFloat = 32
        /// Capsule: buttons, chips, pills, badges, avatars.
        static let full: CGFloat = 9999
    }
}
