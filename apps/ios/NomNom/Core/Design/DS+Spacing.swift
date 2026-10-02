import CoreGraphics

extension DS {
    /// Tailwind spacing scale (`spacing-N` = N × 4pt), aliased from `DSTokens.Spacing`.
    /// Off-scale values are not allowed; half steps use an underscore (`s2_5` = 10pt).
    enum Spacing {
        private typealias T = DSTokens.Spacing
        static let s0_5 = T.s0_5
        static let s1 = T.s1
        static let s1_5 = T.s1_5
        static let s2 = T.s2
        static let s2_5 = T.s2_5
        static let s3 = T.s3
        static let s3_5 = T.s3_5
        static let s4 = T.s4
        static let s5 = T.s5
        static let s6 = T.s6
        static let s7 = T.s7
        static let s8 = T.s8
        static let s9 = T.s9
        static let s10 = T.s10
        static let s11 = T.s11
        static let s12 = T.s12
        static let s14 = T.s14
        static let s16 = T.s16
        static let s20 = T.s20
        static let s24 = T.s24
        static let s28 = T.s28
        static let s36 = T.s36
        static let s48 = T.s48
        static let s64 = T.s64
        static let s72 = T.s72

        // MARK: - Semantic aliases
        // design-system/README.md, "Layout, radius, elevation": "Detail screens:
        // `spacing-4` side gutters, `spacing-7` between blocks (photos, header, score,
        // sections), `spacing-5` inside content cards, `spacing-2` inset for section
        // headers, list rows at least `spacing-14` (`sm` rows `spacing-11`)."

        /// Screen side gutter (`spacing-4`).
        static let gutter = s4
        /// Gap between blocks on a detail screen (`spacing-7`).
        static let block = s7
        /// Padding inside content cards (`spacing-5`).
        static let cardPadding = s5
        /// Inset for section headers (`spacing-2`).
        static let sectionInset = s2
        /// Minimum list-row height (`spacing-14`).
        static let rowMin = s14
        /// Minimum `sm` list-row height (`spacing-11`).
        static let rowMinSm = s11
    }
}

extension DS {
    /// Container widths (`container-*`), aliased from `DSTokens.Container`.
    enum Container {
        /// `container-sm` (384): the measure for a sentence under a title
        /// (PageHeader subtitle, EmptyState message).
        static let sm = DSTokens.Container.sm
    }
}

// MARK: - Deprecated pre-spec names (pure renames of steps; removed in Phase 6)

extension DS.Spacing {
    @available(*, deprecated, message: "Use DS.Spacing.s1")
    static let xxs = s1
    @available(*, deprecated, message: "Use DS.Spacing.s2")
    static let xs = s2
    @available(*, deprecated, message: "Use DS.Spacing.s3")
    static let sm = s3
    @available(*, deprecated, message: "Use DS.Spacing.s4")
    static let md = s4
    @available(*, deprecated, message: "Use DS.Spacing.s6")
    static let sectionCompact = s6
    @available(*, deprecated, message: "Use DS.Spacing.s8")
    static let section = s8
    @available(*, deprecated, message: "Use DS.Spacing.s10")
    static let sectionLarge = s10
    @available(*, deprecated, message: "Use DS.Spacing.s7")
    static let heroInner = s7
    @available(*, deprecated, message: "Use DS.Spacing.s10")
    static let heroToContent = s10
    @available(*, deprecated, message: "Use DS.Spacing.s3_5")
    static let heroDeckPadding = s3_5
    @available(*, deprecated, message: "Use DS.Spacing.gutter")
    static let screenHorizontal = gutter
    @available(*, deprecated, message: "Use DS.Spacing.s5")
    static let screenTop = s5
    @available(*, deprecated, message: "Use DS.Spacing.s11")
    static let screenBottom = s11
}
