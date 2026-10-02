// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// What sits at the start of a ListRow.
enum ListRowLeading {
    /// A person or party: pass a configured Avatar (usually `.sm`).
    case avatar(Avatar)
    /// A meal or recipe thumbnail: PhotoCard `.thumb` (`s12` square).
    case photo(PhotoCardSource)
    /// A leaderboard position as a serif numeral; the top three ink `text-primary`.
    case rank(Int)
    case none
}

/// What sits at the end of a ListRow. Rows take several, laid out in order
/// (e.g. `.score(0.82), .chevron`).
enum ListRowTrailing {
    case badge(Badge)
    /// Normalised 0–1 score as ScoreValue `xs` (an em dash when nil).
    case score(Double?)
    /// An AppButton, normally `size: .sm`.
    case button(AppButton)
    /// A switch labelled by the row title.
    case toggle(Binding<Bool>)
    /// Disclosure; use when the row (or its NavigationLink) navigates.
    case chevron
    /// A key-value row's value: `sans-sm` `text-secondary`.
    case value(String)
    /// Anything else (BurnerMeter, a pair of buttons). Keep it to DS primitives.
    case custom(AnyView)

    /// `.custom` from a view builder.
    static func view<V: View>(@ViewBuilder _ view: () -> V) -> ListRowTrailing {
        .custom(AnyView(view()))
    }
}

/// Renders one trailing slot.
struct ListRowTrailingView: View {
    let slot: ListRowTrailing
    let title: String

    var body: some View {
        switch slot {
        case .badge(let badge):
            badge
        case .score(let score):
            ScoreValue(score: score, size: .xs)
                .frame(minWidth: DS.Spacing.s9, alignment: .trailing)
        case .button(let button):
            button
        case .toggle(let isOn):
            AppToggle(title, isOn: isOn)
        case .chevron:
            Image(systemName: "chevron.right")
                .textStyle(.sansSm, tone: .tertiary, weight: .semibold)
                .accessibilityHidden(true)
        case .value(let value):
            Text(value)
                .textStyle(.sansSm, tone: .secondary, numeric: true)
                .lineLimit(1)
        case .custom(let view):
            view
        }
    }
}

/// Renders the leading slot.
struct ListRowLeadingView: View {
    let slot: ListRowLeading

    var body: some View {
        switch slot {
        case .avatar(let avatar):
            avatar
        case .photo(let source):
            PhotoCard(source, size: .thumb)
                .accessibilityHidden(true)
        case .rank(let rank):
            Text("\(rank)")
                .textStyle(.serifXs, tone: rank <= 3 ? .primary : .tertiary, numeric: true)
                .frame(minWidth: DS.Spacing.s6, alignment: .leading)
                .accessibilityLabel("Rank \(rank)")
        case .none:
            EmptyView()
        }
    }
}
