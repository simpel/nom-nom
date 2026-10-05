import CoreGraphics

extension DS {
    /// Tailwind opacity scale, aliased from `DSTokens.Opacity`.
    enum Opacity {
        private typealias T = DSTokens.Opacity
        static let o0 = T.o0
        static let o5 = T.o5
        static let o10 = T.o10
        static let o15 = T.o15
        static let o20 = T.o20
        static let o25 = T.o25
        static let o30 = T.o30
        static let o40 = T.o40
        static let o50 = T.o50
        static let o60 = T.o60
        static let o70 = T.o70
        static let o75 = T.o75
        static let o80 = T.o80
        static let o90 = T.o90
        static let o95 = T.o95
        static let o100 = T.o100

        // MARK: - Semantic aliases
        // design-system/README.md, "Layout, radius, elevation": "Tints: a fill mixed
        // over its ground at an opacity step — `opacity-10` tinted cards, `opacity-15`
        // reaction badges, `opacity-20` selected cells, `opacity-30` hairlines."
        // README "Motion and states": "Press: `opacity-70` …", "Disabled: `opacity-50`
        // on buttons and fields."

        static let tint = o10
        static let reactionBadge = o15
        static let selected = o20
        static let hairline = o30
        static let disabled = o50
        static let pressed = o70
    }
}
