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

/// A BottomSheet content card: a Card with a `serif-sm` title, an optional
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
        Card(spacing: DS.Spacing.s1) {
            Text(title)
                .textStyle(.serifSm)
                .accessibilityAddTraits(.isHeader)
            if let provenance {
                Text(provenance).textStyle(.sansXs, tone: .tertiary)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(reasons) { reason in
                    if reason.id != reasons.first?.id {
                        Rectangle()
                            .fill(DS.Color.line)
                            .frame(height: 1)
                            .accessibilityHidden(true)
                    }
                    SheetReasonRow(reason: reason)
                }
            }
            .padding(.top, DS.Spacing.s1)
        }
    }
}

private struct SheetReasonRow: View {
    let reason: SheetReason

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(reason.title).textStyle(.sansLg, weight: .semibold)
            Text(reason.text)
                .textStyle(.sansSm, tone: .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DS.Spacing.s3)
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
