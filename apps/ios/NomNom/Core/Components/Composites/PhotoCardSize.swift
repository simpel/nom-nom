import CoreGraphics

/// PhotoCard's `size` axis: the tile's **long edge**, its corner radius and its insets
/// (components/PhotoCard/README.md, "Axes").
///
/// | size | long edge | radius | default format |
/// | --- | --- | --- | --- |
/// | `xs` | `s20` (80) | `radius-xl` | square, no badge (RecipeLinkCard, ListRow) |
/// | `sm` | `s48` (192) | `radius-2xl` | portrait (Timeline) |
/// | `md` | `s48` (192) | `radius-2xl` | square (RecipeCard, grids) |
/// | `lg` | `s72` (288) | `radius-3xl` | portrait (PhotoStrip) |
enum PhotoCardSize: Equatable, CaseIterable {
    case xs
    case sm
    case md
    case lg

    var longEdge: CGFloat {
        switch self {
        case .xs: return DS.Spacing.s20
        case .sm, .md: return DS.Spacing.s48
        case .lg: return DS.Spacing.s72
        }
    }

    var radius: CGFloat {
        switch self {
        case .xs: return DS.Radius.xl
        case .sm, .md: return DS.Radius.xl2
        case .lg: return DS.Radius.xl3
        }
    }

    /// README "default format": xs square · sm portrait · md square · lg portrait.
    var defaultFormat: PhotoCardFormat {
        switch self {
        case .xs, .md: return .square
        case .sm, .lg: return .portrait
        }
    }

    /// README: "Badge: `elevated sm`, `spacing-2` from the bottom-right (`spacing-3` at `lg`)".
    var badgeInset: CGFloat { self == .lg ? DS.Spacing.s3 : DS.Spacing.s2 }

    /// bundle.css `.nn-photo-card__fav`: `spacing-2` from the top-right, `spacing-1` on `xs`.
    var favoriteInset: CGFloat { self == .xs ? DS.Spacing.s1 : DS.Spacing.s2 }

    /// index.d.ts: "xs 80 (RecipeLinkCard, no badge)".
    var showsBadge: Bool { self != .xs }

    /// README: "No photo: … 'No photo yet' (sm, lg)".
    var showsCaption: Bool { self == .sm || self == .lg }
}

/// PhotoCard's `format` axis: the tile's **shape**. Portrait and landscape are both 3:4,
/// so the short edge is three quarters of the long one.
enum PhotoCardFormat: Equatable, CaseIterable {
    case square
    case portrait
    case landscape

    /// README: "`portrait` and `landscape` are both **3:4**, so the short edge is three
    /// quarters of it." The ratio has no token (DS-GAPS.md: xs portrait 60 and lg
    /// portrait 216 are off the spacing scale).
    static let shortEdgeRatio: CGFloat = 3.0 / 4.0 // ds-lint:allow README "both 3:4"

    func width(longEdge: CGFloat) -> CGFloat {
        self == .portrait ? longEdge * Self.shortEdgeRatio : longEdge
    }

    func height(longEdge: CGFloat) -> CGFloat {
        self == .landscape ? longEdge * Self.shortEdgeRatio : longEdge
    }

    /// Width ÷ height, for a tile that fills its column.
    var aspectRatio: CGFloat {
        switch self {
        case .square: return 1
        case .portrait: return Self.shortEdgeRatio
        case .landscape: return 1 / Self.shortEdgeRatio
        }
    }
}
