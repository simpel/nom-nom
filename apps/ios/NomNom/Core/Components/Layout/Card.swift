import SwiftUI

/// Card padding steps (`size`).
enum CardSize: Equatable {
    /// Padding `spacing-4`.
    case sm
    /// Padding `spacing-5`.
    case md

    var padding: CGFloat { self == .sm ? DS.Spacing.s4 : DS.Spacing.s5 }
}

/// Card's colour role (`variant`).
enum CardVariant: Equatable {
    /// The featured card: `primary` at `opacity-10` over `panel`. One per screen.
    case primary
}

/// How a Card arranges its children (`layout`).
enum CardLayout: Equatable {
    /// Children stack in a column, `spacing` apart.
    case block
    /// Rows: padding `spacing-1` `spacing-4` and a `border-hairline` `line` between rows.
    case list
}

/// The one surface: a `panel` card at `radius-3xl` with no border or shadow. Every
/// card in the system (SectionCard, ScoreCard, RatingList, RecipeLinkCard, SheetCard)
/// is this component. Never nest a Card in a Card; rows go in `layout: .list`.
///
/// `spacing` is the gap between children (bundle.css `--nn-gap`, 0 by default): the
/// component that owns the card sets it. `action` makes the card a button with a
/// trailing `text-tertiary` chevron, `opacity-70` on press.
///
/// ```swift
/// Card(layout: .list) {
///     ForEach(members) { MemberRow(member: $0) }
/// }
/// ```
struct Card<Content: View>: View {
    var size: CardSize
    var variant: CardVariant?
    var layout: CardLayout
    var spacing: CGFloat
    var action: (() -> Void)?
    @ViewBuilder var content: Content

    init(
        size: CardSize = .md,
        variant: CardVariant? = nil,
        layout: CardLayout = .block,
        spacing: CGFloat = 0,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.variant = variant
        self.layout = layout
        self.spacing = spacing
        self.action = action
        self.content = content()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        if let action {
            Button(action: action) {
                surface(chevron: true)
            }
            .buttonStyle(AppPressableButtonStyle())
        } else {
            surface(chevron: false)
        }
    }

    private func surface(chevron: Bool) -> some View {
        // bundle.css `.nn-card[data-pressable]`: body and chevron in a row, `spacing-3` apart.
        HStack(spacing: DS.Spacing.s3) {
            arranged
                .frame(maxWidth: .infinity, alignment: .leading)
            if chevron {
                // bundle.css `.nn-card__chevron`: `text-base`, `text-tertiary`.
                Image(systemName: "chevron.right")
                    .textStyle(.sansMd, tone: .tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, layout == .list ? DS.Spacing.s1 : size.padding)
        .padding(.horizontal, layout == .list ? DS.Spacing.s4 : size.padding)
        .background {
            shape
                .fill(DS.Color.panel)
                .overlay {
                    if variant == .primary {
                        shape.fill(DS.Color.primary.opacity(DS.Opacity.tint))
                    }
                }
        }
        .contentShape(shape)
    }

    @ViewBuilder
    private var arranged: some View {
        switch layout {
        case .block:
            VStack(alignment: .leading, spacing: spacing) { content }
        case .list:
            // iOS 17 target: `Group(subviews:)` needs iOS 18, so rows are split
            // with the variadic-view tree to interleave dividers.
            _VariadicView.Tree(CardListRoot()) { content }
        }
    }
}

/// Lays list rows out in a column with a `border-hairline` `line` divider between rows.
private struct CardListRoot: _VariadicView_UnaryViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let lastID = children.last?.id
        VStack(alignment: .leading, spacing: 0) {
            ForEach(children) { child in
                child
                if child.id != lastID {
                    Rectangle()
                        .fill(DS.Color.line)
                        .frame(height: DS.BorderWidth.hairline)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

private struct CardGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                Card(spacing: DS.Spacing.s1_5) {
                    SectionHeader(title: "Recipe")
                    Text("Spaghetti carbonara").textStyle(.serifSm)
                }
                Card(size: .sm, variant: .primary, spacing: DS.Spacing.s3) {
                    Text("Featured card").textStyle(.sansMd, weight: .semibold)
                    Bar(value: 72)
                }
                Card(layout: .list) {
                    ForEach(["Anna", "Joel", "Sam"], id: \.self) { name in
                        ListRow(name, leading: .avatar(Avatar(name: name, size: .sm)))
                    }
                }
                Card(action: {}) {
                    Text("Tappable card").textStyle(.sansMd)
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { CardGallery() }
#Preview("Dark") { CardGallery().preferredColorScheme(.dark) }
