import SwiftUI

/// A Card whose label sits inside it: a SectionHeader, an optional quote, then the
/// content, `spacing-1.5` apart (bundle.css `.nn-section-card`). One shape: a label
/// *above* a card is `DSSection(_:) { Card { … } }`, not this.
///
/// The surface is Card (`panel`, `radius-3xl`, `spacing-5` padding); SectionCard draws
/// nothing of its own. `variant: .primary` tints the card `primary` at `opacity-10`
/// and turns the label `primary-text` semibold. `quote` is the cook's note: italic
/// `serif-xs` in `text-primary`, no quotation marks. `action` makes the card a button
/// with Card's chevron.
///
/// ```swift
/// SectionCard("Household verdict", trailing: "4 of 4 rated", trailingTone: .primary) {
///     Text("Everyone finished their plate.").textStyle(.serifSm)
/// }
/// SectionCard("Joel\u{2019}s note", uppercase: false, quote: meal.notes)
/// ```
struct SectionCard<Content: View>: View {
    var title: String?
    var variant: CardVariant?
    var trailing: String?
    var trailingTone: SectionHeaderTrailingTone
    var uppercase: Bool
    var systemImage: String?
    var quote: String?
    var action: (() -> Void)?
    @ViewBuilder var content: Content

    init(
        _ title: String? = nil,
        variant: CardVariant? = nil,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        uppercase: Bool = true,
        systemImage: String? = nil,
        quote: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.variant = variant
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.uppercase = uppercase
        self.systemImage = systemImage
        self.quote = quote
        self.action = action
        self.content = content()
    }

    var body: some View {
        Card(variant: variant, spacing: DS.Spacing.s1_5, action: action) {
            if let title {
                SectionHeader(
                    title: title,
                    trailing: trailing,
                    trailingTone: trailingTone,
                    systemImage: systemImage,
                    uppercase: uppercase,
                    variant: variant == .primary ? .primary : nil
                )
            }
            if let quote, !quote.isEmpty {
                Text(quote)
                    .textStyle(.serifXs, italic: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension SectionCard where Content == EmptyView {
    /// A text-only card, e.g. the cook's note: `SectionCard("Joel’s note", uppercase: false, quote: …)`.
    init(
        _ title: String? = nil,
        variant: CardVariant? = nil,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        uppercase: Bool = true,
        systemImage: String? = nil,
        quote: String
    ) {
        self.init(
            title, variant: variant, trailing: trailing, trailingTone: trailingTone,
            uppercase: uppercase, systemImage: systemImage, quote: quote
        ) { EmptyView() }
    }
}

private struct SectionCardGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                SectionCard("Household verdict", trailing: "4 of 4 rated", trailingTone: .primary) {
                    Text("Everyone finished their plate.").textStyle(.serifSm)
                    Text("Two people asked for seconds.").textStyle(.sansMd, tone: .secondary)
                }
                SectionCard("Joel\u{2019}s note", uppercase: false, quote: "End of summer pizza night on the deck.")
                SectionCard("Tip from last time", variant: .primary) {
                    Text("Salt the water more than you think.").textStyle(.sansMd, tone: .secondary)
                }
                DSSection("Ingredients", trailing: "6 items") {
                    Card { Text("A label above the card").textStyle(.sansMd) }
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SectionCardGallery() }
#Preview("Dark") { SectionCardGallery().preferredColorScheme(.dark) }
