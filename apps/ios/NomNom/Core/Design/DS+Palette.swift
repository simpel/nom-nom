import SwiftUI

// Raw Stone and Pine ramps, aliased from `DSTokens.Color`. Views consume the
// semantic roles in `DS.Color`, never these ramps; they exist for the few
// places the README itself names a ramp step (e.g. README "Imagery": the photo
// scrim is "`stone-1000` at 72%"). Ramp steps have no dark value in
// tokens.json, so they are the same in both themes.

extension DS.Color {
    enum Stone {
        private typealias T = DSTokens.Color
        static let stone0 = T.stone0
        static let stone25 = T.stone25
        static let stone50 = T.stone50
        static let stone100 = T.stone100
        static let stone200 = T.stone200
        static let stone300 = T.stone300
        static let stone400 = T.stone400
        static let stone500 = T.stone500
        static let stone600 = T.stone600
        static let stone700 = T.stone700
        static let stone800 = T.stone800
        static let stone900 = T.stone900
        static let stone950 = T.stone950
        static let stone1000 = T.stone1000
    }

    enum Pine {
        private typealias T = DSTokens.Color
        static let pine50 = T.pine50
        static let pine100 = T.pine100
        static let pine200 = T.pine200
        static let pine300 = T.pine300
        static let pine400 = T.pine400
        static let pine500 = T.pine500
        static let pine600 = T.pine600
        static let pine700 = T.pine700
        static let pine800 = T.pine800
        static let pine900 = T.pine900
    }
}
