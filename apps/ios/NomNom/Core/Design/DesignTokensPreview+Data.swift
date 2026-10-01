import SwiftUI

/// Swatch tables rendered by `DesignTokensPreview`.
extension DesignTokensPreview {
    typealias Swatch = (name: String, color: Color)

    static let surfaces: [Swatch] = [
        ("bg", DS.Color.bg), ("panel", DS.Color.panel), ("sunken", DS.Color.sunken),
        ("sheet", DS.Color.sheet), ("line", DS.Color.line), ("lineStrong", DS.Color.lineStrong),
        ("linePlaceholder", DS.Color.linePlaceholder), ("track", DS.Color.track),
        ("scrim", DS.Color.scrim), ("grabber", DS.Color.grabber),
        ("textPrimary", DS.Color.textPrimary), ("textSecondary", DS.Color.textSecondary),
        ("textTertiary", DS.Color.textTertiary), ("focusRing", DS.Color.focusRing),
        ("primaryHover", DS.Color.primaryHover), ("primaryMuted", DS.Color.primaryMuted),
    ]

    static var roleSwatches: [Swatch] {
        let roles: [(String, DS.Role)] = [
            ("primary", .primary), ("secondary", .secondary), ("destructive", .destructive),
            ("pro", .pro), ("warning", .warning),
        ]
        return roles.flatMap { name, role in
            [
                (name, role.fill), ("\(name)Soft", role.soft),
                ("\(name)Text", role.text), ("on\(name.capitalized)", role.on),
            ]
        }
    }

    static var reactions: [Swatch] {
        Reaction.allCases.flatMap { reaction in
            [("\(reaction.shortLabel) fill", reaction.fill), ("\(reaction.shortLabel) text", reaction.text)]
        }
    }

    static let stoneRamp: [Swatch] = [
        ("0", DS.Color.Stone.stone0), ("25", DS.Color.Stone.stone25),
        ("50", DS.Color.Stone.stone50), ("100", DS.Color.Stone.stone100),
        ("200", DS.Color.Stone.stone200), ("300", DS.Color.Stone.stone300),
        ("400", DS.Color.Stone.stone400), ("500", DS.Color.Stone.stone500),
        ("600", DS.Color.Stone.stone600), ("700", DS.Color.Stone.stone700),
        ("800", DS.Color.Stone.stone800), ("900", DS.Color.Stone.stone900),
        ("950", DS.Color.Stone.stone950), ("1000", DS.Color.Stone.stone1000),
    ]

    static let pineRamp: [Swatch] = [
        ("50", DS.Color.Pine.pine50), ("100", DS.Color.Pine.pine100),
        ("200", DS.Color.Pine.pine200), ("300", DS.Color.Pine.pine300),
        ("400", DS.Color.Pine.pine400), ("500", DS.Color.Pine.pine500),
        ("600", DS.Color.Pine.pine600), ("700", DS.Color.Pine.pine700),
        ("800", DS.Color.Pine.pine800), ("900", DS.Color.Pine.pine900),
    ]

    static let shadows: [(name: String, level: DS.Shadow)] = [
        ("xs", .xs), ("sm", .sm), ("md", .md), ("lg", .lg), ("xl", .xl),
    ]
}
