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

    /// Pre-v3 spacing the deprecated initialisers still draw. `nil` on the v3 API.
    private var legacyHorizontalPadding: CGFloat?
    private var legacyBottomPadding: CGFloat?
    private var legacyTrailingColor: Color?

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

    /// Pre-v3 API. `inset: true` (the default) drew the `spacing-2` side inset and gap
    /// that now belong to `DSSection`; `inset: false` is `SectionHeader(title:)`.
    @available(*, deprecated, message: "SectionHeader reserves no space: use SectionHeader(title:…) inside DSSection, SectionCard or a Card")
    init(
        _ title: String,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        systemImage: String? = nil,
        uppercase: Bool = true,
        inset: Bool = true,
        variant: SectionHeaderVariant? = nil
    ) {
        self.init(title: title, trailing: trailing, trailingTone: trailingTone, systemImage: systemImage,
                  uppercase: uppercase, variant: variant)
        if inset {
            self.legacyHorizontalPadding = DS.Spacing.sectionInset
            self.legacyBottomPadding = DS.Spacing.s2
        }
    }

    /// Pre-design-system API, kept so existing call sites compile until Phase 5.
    @_disfavoredOverload
    @available(*, deprecated, message: "Use SectionHeader(title:trailing:trailingTone:systemImage:uppercase:variant:)")
    init(
        _ title: String,
        trailingText: String? = nil,
        trailingColor: Color? = nil,
        horizontalPadding: CGFloat = DS.Spacing.s4
    ) {
        self.init(title: title, trailing: trailingText)
        self.legacyTrailingColor = trailingColor
        self.legacyHorizontalPadding = horizontalPadding
    }

    private var trailingColor: Color {
        if let legacyTrailingColor { return legacyTrailingColor }
        return trailingTone == .primary ? DS.Color.primaryText : DS.Color.textTertiary
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
        .padding(.horizontal, legacyHorizontalPadding ?? 0)
        .padding(.bottom, legacyBottomPadding ?? 0)
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
