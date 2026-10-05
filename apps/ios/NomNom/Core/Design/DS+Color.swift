import SwiftUI

// Semantic colour roles. Every value comes from `DSTokens.Color`
// (Generated/DSTokens.generated.swift, built from design-system/tokens.json);
// this file only gives the roles their Swift names. Views consume these roles,
// never the Stone / Pine ramps.

extension DS {
    enum Color {
        private typealias T = DSTokens.Color

        // MARK: - Surfaces

        static let bg = T.bg
        static let panel = T.panel
        static let sunken = T.sunken
        static let sheet = T.sheet
        static let line = T.line
        static let lineStrong = T.lineStrong
        static let lineControl = T.lineControl
        static let track = T.track
        static let scrim = T.scrim
        static let grabber = T.grabber

        // MARK: - Text

        static let textPrimary = T.textPrimary
        static let textSecondary = T.textSecondary
        static let textTertiary = T.textTertiary
        static let focusRing = T.focusRing

        // MARK: - Primary (Pine)

        static let primary = T.primary
        static let primarySoft = T.primarySoft
        static let primaryText = T.primaryText
        static let onPrimary = T.onPrimary
        static let primaryMuted = T.primaryMuted

        // MARK: - Secondary (Stone ink)

        static let secondary = T.secondary
        static let secondarySoft = T.secondarySoft
        static let secondaryText = T.secondaryText
        static let onSecondary = T.onSecondary

        // MARK: - Destructive

        static let destructive = T.destructive
        static let destructiveSoft = T.destructiveSoft
        static let destructiveText = T.destructiveText
        static let onDestructive = T.onDestructive

        // MARK: - Pro (violet, reserved for Nom Nom Pro)

        static let pro = T.pro
        static let proSoft = T.proSoft
        static let proText = T.proText
        static let onPro = T.onPro

        // MARK: - Warning (downward change)

        static let warning = T.warning
        static let warningSoft = T.warningSoft
        static let warningText = T.warningText
        static let onWarning = T.onWarning

        // MARK: - Reaction ramp (rating data only)

        static let reactionInedibleFill = T.reactionInedibleFill
        static let reactionInedibleText = T.reactionInedibleText
        static let reactionBadFill = T.reactionBadFill
        static let reactionBadText = T.reactionBadText
        static let reactionMehFill = T.reactionMehFill
        static let reactionMehText = T.reactionMehText
        static let reactionGoodFill = T.reactionGoodFill
        static let reactionGoodText = T.reactionGoodText
        static let reactionGreatFill = T.reactionGreatFill
        static let reactionGreatText = T.reactionGreatText
        static let reactionAmazingFill = T.reactionAmazingFill
        static let reactionAmazingText = T.reactionAmazingText

        // MARK: - Chart series (assign by stable member index, never cycled)

        static let chartSeries1 = T.chartSeries1
        static let chartSeries2 = T.chartSeries2
        static let chartSeries3 = T.chartSeries3
        static let chartSeries4 = T.chartSeries4
        static let chartSeries5 = T.chartSeries5
        static let chartSeries6 = T.chartSeries6
        static let chartSeries7 = T.chartSeries7

        static let chartSeries: [SwiftUI.Color] = [
            chartSeries1, chartSeries2, chartSeries3, chartSeries4,
            chartSeries5, chartSeries6, chartSeries7,
        ]
    }
}

// MARK: - Roles

extension DS {
    /// One colour role: fill, tinted ground, text ink and ink-on-fill.
    /// README "Colour": every role has `{role}`, `{role}-soft`, `{role}-text`, `on-{role}`.
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
