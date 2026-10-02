import SwiftUI

/// ListRow `size`: `md` rows are at least `spacing-14` tall, `sm` rows `spacing-11`.
enum ListRowSize: Equatable {
    case sm, md

    var minHeight: CGFloat { self == .sm ? DS.Spacing.rowMinSm : DS.Spacing.rowMin }

    /// bundle.css `.nn-row` padding `spacing-3` (`sm`: `spacing-2`).
    var verticalPadding: CGFloat { self == .sm ? DS.Spacing.s2 : DS.Spacing.s3 }
}

/// ListRow `tone`. `destructive` inks the row `destructive-text` (Leave, Delete account);
/// the word carries it, so a destructive row takes no icon.
enum ListRowTone: Equatable {
    case destructive
}

/// What sits at the start of a ListRow (README: "Avatar, PhotoCard `xs`, rank numeral, Icon").
enum ListRowLeading {
    /// A person or party: pass a configured Avatar (usually `.sm`).
    case avatar(Avatar)
    /// A meal or recipe thumbnail, PhotoCard `xs`.
    case photo(PhotoCardSource)
    /// A position, set as `Text serif-xs numeric` (README: "never as a Badge").
    case rank(Int)
    /// A single SF Symbol in the lead's `text-tertiary`.
    case icon(String)
    case none
}

/// ListRow's trailing slot (README: "Badge, ScoreValue `xs`, AppButton `sm`, Toggle").
/// A number goes in ListRow's `value`, not here.
enum ListRowTrailing {
    case badge(Badge)
    /// Normalised 0–1 score as ScoreValue `xs` (an em dash when nil).
    case score(Double?)
    /// An AppButton `sm`.
    case button(AppButton)
    /// The Toggle shape: an AppToggle named by the row's title.
    case toggle(Binding<Bool>)
    /// Any other DS control (a TactileTasteSelector). Treated as interactive.
    case custom(AnyView)

    /// `.custom` from a view builder.
    static func view<V: View>(@ViewBuilder _ view: () -> V) -> ListRowTrailing {
        .custom(AnyView(view()))
    }

    /// A control: giving one to a pressable row splits the row so a button never
    /// sits inside a button.
    var isInteractive: Bool {
        switch self {
        case .badge, .score: return false
        case .button, .toggle, .custom: return true
        }
    }
}

/// The second trailing element README allows: a `ghost` icon-only AppButton (the
/// invite's revoke ✕). The role defaults to `destructive`.
struct ListRowIconAction {
    let icon: AppButtonIcon
    let accessibilityLabel: String
    var variant: DSVariant = .destructive
    var isLoading: Bool = false
    let perform: () -> Void

    var button: AppButton {
        AppButton(icon: icon, accessibilityLabel: accessibilityLabel, variant: variant,
                  appearance: .ghost, isLoading: isLoading, action: perform)
    }
}

/// Renders the trailing slot.
struct ListRowTrailingView: View {
    let slot: ListRowTrailing
    let title: String

    var body: some View {
        switch slot {
        case .badge(let badge):
            badge
        case .score(let score):
            // ListRow README is silent on the width; bundle.css `.nn-rating-row__score`
            // gives a row score `min-width: spacing-9`, applied to every score row so
            // the numerals line up down a list.
            ScoreValue(score: score, size: .xs)
                .frame(minWidth: DS.Spacing.s9, alignment: .trailing)
        case .button(let button):
            button
        case .toggle(let isOn):
            AppToggle(title, isOn: isOn)
        case .custom(let view):
            view
        }
    }
}

/// Renders the leading slot (bundle.css `.nn-row__lead`: centred, at least `spacing-6`
/// wide, `text-tertiary`).
struct ListRowLeadingView: View {
    let slot: ListRowLeading

    var body: some View {
        switch slot {
        case .avatar(let avatar):
            avatar
        case .photo(let source):
            PhotoCard(source, size: .xs)
                .accessibilityHidden(true)
        case .rank(let rank):
            Text("\(rank)")
                .textStyle(.serifXs, numeric: true)
                .frame(minWidth: DS.Spacing.s6)
                .accessibilityLabel("Rank \(rank)")
        case .icon(let name):
            // An icon takes the row's `text-base` (bundle.css `.nn-icon` is 1em).
            Image(systemName: name)
                .textStyle(.sansMd, tone: .tertiary)
                .frame(minWidth: DS.Spacing.s6)
                .accessibilityHidden(true)
        case .none:
            EmptyView()
        }
    }
}
