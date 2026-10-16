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
/// Axes: case (`uppercase`), trailing (`trailing` + `trailingTone`), emphasis
/// (`variant`) and the section action (`action`). The trailing slot takes a figure — a
/// byline, a score, a count the person acts on ("Waiting for your rating 3"), never a
/// plain list length — and never a button. The one verb a section offers is `action`: a
/// soft `sm` AppButton on the right ("New party", "Log meal", "See all"), drawn only when
/// the viewer can act. The title is never truncated: it wraps to as many lines as it
/// needs and the figure stays aligned to its first line.
struct SectionHeader: View {
    let title: String
    var trailing: String?
    var trailingTone: SectionHeaderTrailingTone
    var systemImage: String?
    var uppercase: Bool
    var variant: SectionHeaderVariant?
    var action: SectionAction?

    init(
        title: String,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        systemImage: String? = nil,
        uppercase: Bool = true,
        variant: SectionHeaderVariant? = nil,
        action: SectionAction? = nil
    ) {
        self.title = title
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.systemImage = systemImage
        self.uppercase = uppercase
        self.variant = variant
        self.action = action
    }

    private var trailingColor: Color {
        trailingTone == .primary ? DS.Color.primaryText : DS.Color.textTertiary
    }

    var body: some View {
        // The action is a real 44pt button, so the row centres on it; without one the
        // figure stays on the title's first line.
        HStack(alignment: action == nil ? .firstTextBaseline : .center, spacing: DS.Spacing.s2) {
            label
            if let action {
                SectionActionView(action: action)
            }
        }
        // bundle.css `.nn-section-header[data-action] { min-height: spacing-11 }`.
        .frame(minHeight: action == nil ? nil : DS.Spacing.s11)
    }

    /// The title, its optional icon and the figure: one VoiceOver element, so the button
    /// beside it stays its own.
    private var label: some View {
        // The title wraps onto as many lines as it needs; the figure stays on the first.
        HStack(alignment: action == nil ? .firstTextBaseline : .center, spacing: DS.Spacing.s2) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s1_5) {
                if let systemImage {
                    // bundle.css: the title's icon is `text-sm`.
                    Image(systemName: systemImage)
                        .textStyle(.sansSm, tone: nil)
                        .accessibilityHidden(true)
                }
                Text(uppercase ? title.uppercased() : title)
                    .tracking(uppercase ? DS.TextStyle.sansXs.trackingWidest : 0)
                    .textStyle(.sansXs, tone: nil, weight: variant == .primary ? .semibold : nil)
                    .fixedSize(horizontal: false, vertical: true)
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
            SectionHeader(title: "Meal history", action: SectionAction("Log meal", accessibilityLabel: "Log a meal") {})
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SectionHeaderGallery() }
#Preview("Dark") { SectionHeaderGallery().preferredColorScheme(.dark) }
