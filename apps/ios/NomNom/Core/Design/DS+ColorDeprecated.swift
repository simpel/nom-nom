import SwiftUI

// Pre-design-system colour names, kept compiling until Phase 6 removes them.
// Each maps to the nearest spec role.

extension DS.Color {
    @available(*, deprecated, renamed: "primary")
    static var accent: SwiftUI.Color { primary }

    @available(*, deprecated, renamed: "primaryText")
    static var accentText: SwiftUI.Color { primaryText }

    @available(*, deprecated, renamed: "primarySoft")
    static var accentSoft: SwiftUI.Color { primarySoft }

    enum Pro {
        @available(*, deprecated, message: "Use DS.Color.proSoft")
        static var proSoft: SwiftUI.Color { DS.Color.proSoft }

        /// No spec equivalent: the system draws no borders on Pro surfaces.
        /// Approximated as `pro-text` at the hairline opacity (30%).
        @available(*, deprecated, message: "No spec token; drop the border or use .dsHairline()")
        static var proBorder: SwiftUI.Color { DS.Color.proText.opacity(DS.Opacity.o30) }

        @available(*, deprecated, message: "Use DS.Color.proText")
        static var proAccent: SwiftUI.Color { DS.Color.proText }

        @available(*, deprecated, message: "Use DS.Color.pro")
        static var proDeep: SwiftUI.Color { DS.Color.pro }
    }

    enum Chart {
        @available(*, deprecated, message: "Use DS.Color.primary")
        static var total: SwiftUI.Color { DS.Color.primary }

        @available(*, deprecated, message: "Use DS.Color.chartSeries1")
        static var primaryComparison: SwiftUI.Color { DS.Color.chartSeries1 }

        @available(*, deprecated, message: "Use DS.Color.line")
        static var gridLine: SwiftUI.Color { DS.Color.line }

        @available(*, deprecated, message: "Use DS.Color.chartSeries")
        static var series: [SwiftUI.Color] { DS.Color.chartSeries }
    }
}
