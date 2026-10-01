import SwiftUI

/// Where SectionCard puts its label.
enum SectionCardLayout: Equatable {
    /// A screen section: inset SectionHeader above the card (DSSection + Card).
    case stacked
    /// A note or callout: SectionHeader pre-header inside the card, `s1_5` above the content.
    case inset
}

/// The one content card: a `panel` Card with a SectionHeader above it (`stacked`)
/// or inside it (`inset`). `featured` tints it `primary` at 10% and turns an inset
/// label `primary-text`. `quote` sets the cook's note in italic `serif-xs`.
///
/// ```swift
/// SectionCard("Household verdict", trailing: "4 of 4 rated", trailingTone: .primary) { … }
/// SectionCard("Joel\u{2019}s note", layout: .inset, uppercase: false, quote: meal.notes)
/// ```
struct SectionCard<Content: View>: View {
    var title: String?
    var layout: SectionCardLayout
    var featured: Bool
    var trailing: String?
    var trailingTone: SectionHeaderTrailingTone
    var uppercase: Bool
    var systemImage: String?
    var quote: String?
    @ViewBuilder var content: Content

    init(
        _ title: String? = nil,
        layout: SectionCardLayout = .stacked,
        featured: Bool = false,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        uppercase: Bool = true,
        systemImage: String? = nil,
        quote: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.layout = layout
        self.featured = featured
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.uppercase = uppercase
        self.systemImage = systemImage
        self.quote = quote
        self.content = content()
    }

    var body: some View {
        switch layout {
        case .stacked:
            if let title {
                DSSection(
                    title,
                    trailing: trailing,
                    trailingTone: trailingTone,
                    systemImage: systemImage,
                    uppercase: uppercase
                ) {
                    card(spacing: DS.Spacing.s3) { cardContent(withHeader: false) }
                }
            } else {
                card(spacing: DS.Spacing.s3) { cardContent(withHeader: false) }
            }
        case .inset:
            card(spacing: DS.Spacing.s1_5) { cardContent(withHeader: true) }
        }
    }

    private func card<C: View>(spacing: CGFloat, @ViewBuilder _ inner: () -> C) -> some View {
        Card(featured: featured, spacing: spacing, content: inner)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func cardContent(withHeader: Bool) -> some View {
        if withHeader, let title {
            SectionHeader(
                title,
                trailing: trailing,
                trailingTone: trailingTone,
                systemImage: systemImage,
                uppercase: uppercase,
                inset: false,
                variant: featured ? .primary : nil
            )
        }
        if let quote, !quote.isEmpty {
            Text(quote)
                .textStyle(.serifXs, italic: true)
                .fixedSize(horizontal: false, vertical: true)
        }
        content
    }
}

extension SectionCard where Content == EmptyView {
    /// A text-only card, e.g. the cook's note: `SectionCard("Joel’s note", layout: .inset, quote: …)`.
    init(
        _ title: String? = nil,
        layout: SectionCardLayout = .inset,
        featured: Bool = false,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        uppercase: Bool = true,
        systemImage: String? = nil,
        quote: String
    ) {
        self.init(
            title, layout: layout, featured: featured, trailing: trailing,
            trailingTone: trailingTone, uppercase: uppercase, systemImage: systemImage,
            quote: quote
        ) { EmptyView() }
    }
}

private struct SectionCardGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.block) {
                SectionCard("Household verdict", trailing: "4 of 4 rated", trailingTone: .primary) {
                    Text("Everyone loved it.").textStyle(.serifSm)
                    Text("Two people asked for seconds.").textStyle(.sansMd, tone: .secondary)
                }
                SectionCard("Joel\u{2019}s note", uppercase: false, quote: "End of summer pizza night on the deck.")
                SectionCard("Tip from last time", layout: .inset, featured: true) {
                    Text("Salt the water more than you think.").textStyle(.sansMd, tone: .secondary)
                }
                SectionCard {
                    Text("A card without a header").textStyle(.sansMd)
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SectionCardGallery() }
#Preview("Dark") { SectionCardGallery().preferredColorScheme(.dark) }
