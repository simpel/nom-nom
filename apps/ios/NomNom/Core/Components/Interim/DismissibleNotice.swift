// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// An inline, dismissible message in the `warning` role: `warning-soft` ground,
/// `warning-text` copy, `radius-3xl`, with a close button on the trailing edge.
/// The DS has no notice or banner; the Badge README keeps `warning` for change, so
/// this borrows the role's soft ground and text tokens for a recoverable problem.
struct DismissibleNotice: View {
    let message: String
    var onDismiss: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Text(message)
                .textStyle(.sansSm)
                .foregroundStyle(DS.Color.warningText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DS.Spacing.s3)
            AppButton(
                icon: "xmark",
                accessibilityLabel: "Dismiss",
                variant: .secondary,
                appearance: .ghost,
                action: onDismiss
            )
        }
        .padding(.leading, DS.Spacing.s5)
        .padding(.trailing, DS.Spacing.s1)
        .background(shape.fill(DS.Color.warningSoft))
        .accessibilityElement(children: .contain)
    }
}
