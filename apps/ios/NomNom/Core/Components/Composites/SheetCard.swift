import SwiftUI

/// One reason inside a SheetCard: a `sans-lg` semibold title and a `sans-sm`
/// `text-secondary` sentence.
struct SheetReason: Identifiable, Hashable {
    let id: String
    let title: String
    let text: String

    init(id: String? = nil, title: String, text: String) {
        self.id = id ?? title
        self.title = title
        self.text = text
    }
}

/// A BottomSheet content card: a Card (gap 0) with a `serif-sm` title, an optional
/// `sans-xs` provenance line ("AI summary of Joel’s 54 past ratings") and
/// SheetReason rows divided by `line`.
struct SheetCard: View {
    let title: String
    var provenance: String?
    var reasons: [SheetReason]

    init(_ title: String, provenance: String? = nil, reasons: [SheetReason]) {
        self.title = title
        self.provenance = provenance
        self.reasons = reasons
    }

    var body: some View {
        Card {
            Text(title)
                .textStyle(.serifSm)
                .accessibilityAddTraits(.isHeader)
            if let provenance {
                // The README names no ink for provenance; it is metadata, so `text-tertiary`.
                Text(provenance).textStyle(.sansXs, tone: .tertiary)
            }
            ForEach(reasons) { reason in
                SheetReasonRow(reason: reason, isLast: reason.id == reasons.last?.id)
            }
        }
    }
}

/// bundle.css `.nn-reason`: gap `spacing-1`, padding `spacing-3.5` 0, a `line` rule
/// below; the last reason has no rule and no bottom padding.
private struct SheetReasonRow: View {
    let reason: SheetReason
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(reason.title).textStyle(.sansLg, weight: .semibold)
            Text(reason.text)
                .textStyle(.sansSm, tone: .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DS.Spacing.s3_5)
        .padding(.bottom, isLast ? 0 : DS.Spacing.s3_5)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(DS.Color.line)
                    .frame(height: DS.BorderWidth.hairline)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SheetCardGallery: View {
    var body: some View {
        SheetCard(
            "Why Joel loved it",
            provenance: "AI summary of Joel\u{2019}s 54 past ratings",
            reasons: [
                SheetReason(title: "Crispy crust", text: "He rates wood-fired pizza 12 points above his usual."),
                SheetReason(title: "Fresh basil", text: "Herb-forward dishes are his most consistent favourites."),
                SheetReason(title: "Shared outdoors", text: "Meals on the deck score higher across the household."),
            ]
        )
        .padding(DS.Spacing.s5)
        .background(DS.Color.sheet)
    }
}

#Preview("Light") { SheetCardGallery() }
#Preview("Dark") { SheetCardGallery().preferredColorScheme(.dark) }
