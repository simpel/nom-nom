import SwiftUI

/// Ink for SectionHeader's trailing figure (`trailingVariant`).
enum SectionHeaderTrailingTone: Equatable {
    /// `text-tertiary`.
    case secondary
    /// `primary-text`, for a live count.
    case primary
}

/// SectionHeader's emphasis (`variant`).
enum SectionHeaderVariant: Equatable {
    /// Title in `primary-text` semibold. Only inside a featured card, on one label there.
    case primary
}

/// The one small label, the same wherever it sits: a `sans-xs` title in
/// `text-tertiary` (uppercase + `tracking-widest` by default), an optional icon before
/// it and one optional figure on the right. It is the heading above a list and the
/// eyebrow inside a card.
///
/// It draws no surface and **reserves no space around itself**: the parent places it.
/// Above content use `DSSection` (which supplies the `spacing-2` inset and gap); inside
/// a card use `SectionCard` or the card's own padding.
///
/// Axes: case (`uppercase`), trailing (`trailing` + `trailingTone`) and emphasis
/// (`variant`). The trailing slot takes a figure — a count, a byline, a score — never a
/// second label or a button. The title truncates before the figure does.
struct SectionHeader: View {
    let title: String
    var trailing: String?
    var trailingTone: SectionHeaderTrailingTone
    var systemImage: String?
    var uppercase: Bool
    var variant: SectionHeaderVariant?

    init(
        title: String,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        systemImage: String? = nil,
        uppercase: Bool = true,
        variant: SectionHeaderVariant? = nil
    ) {
        self.title = title
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.systemImage = systemImage
        self.uppercase = uppercase
        self.variant = variant
    }

    private var trailingColor: Color {
        trailingTone == .primary ? DS.Color.primaryText : DS.Color.textTertiary
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s1_5) {
                if let systemImage {
                    // bundle.css: the title's icon is `text-sm`.
                    Image(systemName: systemImage)
                        .textStyle(.sansSm, tone: nil)
                        .accessibilityHidden(true)
                }
                Text(uppercase ? title.uppercased() : title)
                    .tracking(uppercase ? DS.TextStyle.sansXs.trackingWidest : 0)
                    .textStyle(.sansXs, tone: nil, weight: variant == .primary ? .semibold : nil, lines: 1)
                    .truncationMode(.tail)
            }
            .foregroundStyle(variant == .primary ? DS.Color.primaryText : DS.Color.textTertiary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(title)

            Spacer(minLength: 0)

            if let trailing {
                // The README does not name the figure's step; it shares the label's
                // `sans-xs` line (DS-GAPS.md).
                Text(trailing)
                    .textStyle(.sansXs, tone: nil, numeric: true, lines: 1)
                    .foregroundStyle(trailingColor)
                    .layoutPriority(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SectionHeaderGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s5) {
            SectionHeader(title: "Who rated", trailing: "5 of 6", trailingTone: .primary)
            SectionHeader(title: "Ingredients", trailing: "6 items")
            SectionHeader(title: "Italian")
            SectionHeader(title: "Joel\u{2019}s note", uppercase: false)
            SectionHeader(title: "Household score", systemImage: "person.2", variant: .primary)
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SectionHeaderGallery() }
#Preview("Dark") { SectionHeaderGallery().preferredColorScheme(.dark) }
