import SwiftUI

// Semantic colour roles from the design system (`tokens.json`). Every token is
// defined here in Swift as a light/dark pair; `{alias}` values are resolved to
// their target and a token without a dark value reuses its light value.

extension DS {
    enum Color {
        typealias C = SwiftUI.Color
        private typealias H = DS.Color.Hex

        // MARK: - Surfaces

        /// Screen ground behind every list and scroll view.
        static let bg = C(light: "#f2f3f5", dark: H.stone1000)
        /// Cards, rows, floating icon buttons.
        static let panel = C(light: H.stone0, dark: H.stone900)
        /// Filled inputs, in-sheet buttons, placeholders.
        static let sunken = C(light: "#e9eaec", dark: H.stone800)
        /// Bottom-sheet ground; its cards are `panel`.
        static let sheet = C(light: "#f7f7f8", dark: "#15181d")
        /// 1px row dividers inside a card list.
        static let line = C(light: "#ecedef", dark: H.stone800)
        /// Timeline rail, outlined borders.
        static let lineStrong = C(light: "#d5d8dc", dark: H.stone700)
        /// Dashed border of the Add photo tile.
        static let linePlaceholder = C(light: "#b9bec4", dark: H.stone700)
        /// Unfilled part of a progress or score bar.
        static let track = C(light: "#e6e8ea", dark: "#3a3f46")
        /// Dims the screen behind a sheet.
        static let scrim = C(light: "#00000066", dark: "#00000099")
        /// Sheet grabber handle.
        static let grabber = C(light: "#c9ccd0", dark: H.stone700)

        // MARK: - Over photos (fixed in both themes)

        /// Glyphs drawn straight on a photo (PhotoCard's favourite heart).
        static let onPhoto = C(light: "#ffffff")
        /// Black 45% disc behind a glyph on a photo (PhotoCard README).
        static let photoDisc = C(light: "#00000073")

        // MARK: - Text

        static let textPrimary = C(light: "#16181a", dark: H.stone100)
        static let textSecondary = C(light: "#3a3f45", dark: H.stone300)
        static let textTertiary = C(light: "#5b6168", dark: H.stone400)
        static let focusRing = C(light: "#0f6b5c", dark: H.pine400)

        // MARK: - Primary (Pine)

        static let primary = C(light: "#0f6b5c", dark: H.pine400)
        static let primarySoft = C(light: "#e3f1ee", dark: H.pine900)
        static let primaryText = C(light: "#0f6b5c", dark: H.pine300)
        static let onPrimary = C(light: "#ffffff")
        static let primaryHover = C(light: "#0a4f44", dark: H.pine300)
        static let primaryMuted = C(light: "#8fbfb4", dark: "#2e6b62")

        // MARK: - Secondary (Stone ink)

        static let secondary = textPrimary
        static let secondarySoft = sunken
        static let secondaryText = textSecondary
        static let onSecondary = panel

        // MARK: - Destructive

        static let destructive = C(light: "#ff3b30", dark: "#ff453a")
        static let destructiveSoft = C(light: "#ffe2e0", dark: "#3e2629")
        static let destructiveText = C(light: "#c4001a", dark: "#ff6961")
        static let onDestructive = C(light: "#ffffff")

        // MARK: - Pro (violet, reserved for Nom Nom Pro)

        static let pro = C(light: "#2b174d", dark: "#4a2f82")
        static let proSoft = C(light: "#f4f0f9", dark: "#1a1130")
        static let proText = C(light: "#7242c2", dark: "#9e7ee0")
        static let onPro = C(light: "#ffffff")

        // MARK: - Warning (downward change)

        static let warningText = C(light: "#9a4418", dark: "#ee8e64")
        static let warning = warningText
        static let warningSoft = C(light: "#fbede4", dark: "#2e1a10")
        static let onWarning = C(light: "#ffffff", dark: H.stone900)

        // MARK: - Reaction ramp (the only saturated colour; rating data only)

        static let reactionInedibleFill = C(light: "#bf3a37", dark: "#e97970")
        static let reactionInedibleText = C(light: "#a51e21", dark: "#e97970")
        static let reactionBadFill = C(light: "#d16633", dark: "#ee8e64")
        static let reactionBadText = C(light: "#9b3400", dark: "#ee8e64")
        static let reactionMehFill = C(light: "#d3a032", dark: "#e4b65c")
        static let reactionMehText = C(light: "#774d00", dark: "#e4b65c")
        static let reactionGoodFill = C(light: "#7ba853", dark: "#a0ca7f")
        static let reactionGoodText = C(light: "#3c6211", dark: "#a0ca7f")
        static let reactionGreatFill = C(light: "#2e985e", dark: "#71c791")
        static let reactionGreatText = C(light: "#006836", dark: "#71c791")
        static let reactionAmazingFill = C(light: "#247f63", dark: "#62bc9c")
        static let reactionAmazingText = C(light: "#00684c", dark: "#62bc9c")

        // MARK: - Chart series (assign by stable member index, never cycled)

        static let chartSeries1 = C(light: "#2a78d6", dark: "#3987e5")
        static let chartSeries2 = C(light: "#eb6834", dark: "#d95926")
        static let chartSeries3 = C(light: "#1baf7a", dark: "#199e70")
        static let chartSeries4 = C(light: "#eda100", dark: "#c98500")
        static let chartSeries5 = C(light: "#e87ba4", dark: "#d55181")
        static let chartSeries6 = C(light: "#008300", dark: "#008300")
        static let chartSeries7 = C(light: "#e34948", dark: "#e66767")

        static let chartSeries: [SwiftUI.Color] = [
            chartSeries1, chartSeries2, chartSeries3, chartSeries4,
            chartSeries5, chartSeries6, chartSeries7,
        ]
    }
}

// MARK: - Roles

extension DS {
    /// One colour role: fill, tinted ground, text ink and ink-on-fill.
    /// Components pick a role with `variant` and paint it with `appearance`.
    struct Role {
        let fill: SwiftUI.Color
        let soft: SwiftUI.Color
        let text: SwiftUI.Color
        let on: SwiftUI.Color

        static let primary = Role(
            fill: DS.Color.primary, soft: DS.Color.primarySoft,
            text: DS.Color.primaryText, on: DS.Color.onPrimary
        )
        static let secondary = Role(
            fill: DS.Color.secondary, soft: DS.Color.secondarySoft,
            text: DS.Color.secondaryText, on: DS.Color.onSecondary
        )
        static let destructive = Role(
            fill: DS.Color.destructive, soft: DS.Color.destructiveSoft,
            text: DS.Color.destructiveText, on: DS.Color.onDestructive
        )
        static let pro = Role(
            fill: DS.Color.pro, soft: DS.Color.proSoft,
            text: DS.Color.proText, on: DS.Color.onPro
        )
        static let warning = Role(
            fill: DS.Color.warning, soft: DS.Color.warningSoft,
            text: DS.Color.warningText, on: DS.Color.onWarning
        )
    }
}
