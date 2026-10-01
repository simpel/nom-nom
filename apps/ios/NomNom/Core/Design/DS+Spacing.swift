import CoreGraphics

extension DS {
    /// Tailwind spacing scale: step N = N × 4pt (`spacing-N` in `tokens.json`).
    /// Off-scale values are not allowed; half steps use an underscore (`s2_5` = 10pt).
    enum Spacing {
        static let s0_5: CGFloat = 2
        static let s1: CGFloat = 4
        static let s1_5: CGFloat = 6
        static let s2: CGFloat = 8
        static let s2_5: CGFloat = 10
        static let s3: CGFloat = 12
        static let s3_5: CGFloat = 14
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s7: CGFloat = 28
        static let s8: CGFloat = 32
        static let s9: CGFloat = 36
        static let s10: CGFloat = 40
        static let s11: CGFloat = 44
        static let s12: CGFloat = 48
        static let s14: CGFloat = 56
        static let s16: CGFloat = 64
        static let s20: CGFloat = 80
        static let s24: CGFloat = 96
        static let s28: CGFloat = 112
        static let s36: CGFloat = 144
        static let s48: CGFloat = 192
        static let s64: CGFloat = 256
        static let s72: CGFloat = 288

        // MARK: - Semantic aliases (detail-screen layout)

        /// Screen side gutter.
        static let gutter = s4
        /// Gap between blocks on a detail screen (photos, header, score, sections).
        static let block = s7
        /// Padding inside content cards (score, note, sheet cards).
        static let cardPadding = s5
        /// Inset for section headers.
        static let sectionInset = s2
        /// Minimum list-row height.
        static let rowMin = s14
    }
}

// MARK: - Deprecated pre-spec names (current values, so layout doesn't shift yet)

extension DS.Spacing {
    @available(*, deprecated, message: "Use DS.Spacing.s1")
    static let xxs: CGFloat = 4
    @available(*, deprecated, message: "Use DS.Spacing.s2")
    static let xs: CGFloat = 8
    @available(*, deprecated, message: "Use DS.Spacing.s3")
    static let sm: CGFloat = 12
    @available(*, deprecated, message: "Use DS.Spacing.s4")
    static let md: CGFloat = 16
    @available(*, deprecated, message: "Use DS.Spacing.s6")
    static let sectionCompact: CGFloat = 24
    @available(*, deprecated, message: "Use DS.Spacing.s8")
    static let section: CGFloat = 32
    @available(*, deprecated, message: "Use DS.Spacing.s10")
    static let sectionLarge: CGFloat = 40
    @available(*, deprecated, message: "Use DS.Spacing.s7")
    static let heroInner: CGFloat = 28
    @available(*, deprecated, message: "Use DS.Spacing.s10")
    static let heroToContent: CGFloat = 40
    @available(*, deprecated, message: "Use DS.Spacing.s3_5")
    static let heroDeckPadding: CGFloat = 14
    @available(*, deprecated, message: "Use DS.Spacing.gutter")
    static let screenHorizontal: CGFloat = 16
    @available(*, deprecated, message: "Use DS.Spacing.s5")
    static let screenTop: CGFloat = 20
    @available(*, deprecated, message: "Use DS.Spacing.s11")
    static let screenBottom: CGFloat = 44
}
