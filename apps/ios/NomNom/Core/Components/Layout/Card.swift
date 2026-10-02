import SwiftUI

/// Card padding steps.
enum CardSize: Equatable {
    /// Padding `s4`.
    case sm
    /// Padding `s5`.
    case md

    var padding: CGFloat { self == .sm ? DS.Spacing.s4 : DS.Spacing.s5 }
}

/// How a Card arranges its children.
enum CardLayout: Equatable {
    /// Children stack in a column with `spacing` between them.
    case block
    /// Rows: `s1` vertical / `s4` horizontal padding and a 1pt `line` between rows.
    case list
}

/// The one surface: a `panel` card at `radius-3xl` with no border or shadow.
/// Never nest a Card in a Card; rows go in `layout: .list`, not in their own cards.
///
/// ```swift
/// Card(layout: .list) {
///     ForEach(members) { MemberRow(member: $0) }
/// }
/// ```
struct Card<Content: View>: View {
    var size: CardSize
    /// `primary` at 10% over `panel`; one per screen.
    var featured: Bool
    var layout: CardLayout
    var spacing: CGFloat
    var action: (() -> Void)?
    @ViewBuilder var content: Content

    init(
        size: CardSize = .md,
        featured: Bool = false,
        layout: CardLayout = .block,
        spacing: CGFloat = DS.Spacing.s3,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.featured = featured
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
        HStack(spacing: DS.Spacing.s3) {
            arranged
                .frame(maxWidth: .infinity, alignment: .leading)
            if chevron {
                Image(systemName: "chevron.right")
                    .textStyle(.sansSm, tone: .tertiary, weight: .semibold)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, layout == .list ? DS.Spacing.s1 : size.padding)
        .padding(.horizontal, layout == .list ? DS.Spacing.s4 : size.padding)
        .background {
            shape
                .fill(DS.Color.panel)
                .overlay {
                    if featured {
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

/// Lays list rows out in a column with a 1pt `line` divider between rows.
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
                        .frame(height: 1)
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
                Card {
                    SectionHeader("Recipe", inset: false)
                    Text("Spaghetti carbonara").textStyle(.serifSm)
                }
                Card(size: .sm, featured: true) {
                    Text("Featured card").textStyle(.sansMd, weight: .semibold)
                    Bar(value: 72)
                }
                Card(layout: .list) {
                    ForEach(["Anna", "Joel", "Sam"], id: \.self) { name in
                        HStack(spacing: DS.Spacing.s3) {
                            Avatar(name: name, size: .sm)
                            Text(name).textStyle(.sansMd)
                        }
                        .frame(minHeight: DS.Spacing.rowMin)
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
