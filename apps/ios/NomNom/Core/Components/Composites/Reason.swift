import SwiftUI

/// One reason (`ReasonProps`, BottomSheet README): a title and its detail, inside a
/// SheetCard or a ProSection. Drawn by ReasonRow: a `sans-lg` semibold title and a `sans-sm`
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

/// bundle.css `.nn-reason`: gap `spacing-1`, padding `spacing-3.5` 0, a `line` rule
/// below; the last reason has no rule and no bottom padding.
struct ReasonRow: View {
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


/// Reasons stacked with `line` rules between them, outside a SheetCard (a ProSection).
struct ReasonList: View {
    let reasons: [SheetReason]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(reasons) { reason in
                ReasonRow(reason: reason, isLast: reason.id == reasons.last?.id)
            }
        }
    }
}
