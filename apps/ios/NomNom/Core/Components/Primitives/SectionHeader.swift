import SwiftUI

/// Ink for SectionHeader's trailing text.
enum SectionHeaderTrailingTone: Equatable {
    /// `text-tertiary`.
    case secondary
    /// `primary-text`, for a live count.
    case primary
}

/// SectionHeader's colour variant.
enum SectionHeaderVariant: Equatable {
    /// Title in `primary-text` semibold, for a featured card.
    case primary
}

/// The one label for section heads and pre-headers: a `sans-xs` semibold title in
/// `text-tertiary` (uppercase + `tracking-widest` by default), an optional icon and
/// optional trailing text. Trailing text is never a button.
///
/// - `inset: true`: a section head above content (`s2` side inset and below, trailing `sans-sm`).
/// - `inset: false`: a pre-header inside a card or header (no inset, trailing `sans-xs`).
struct SectionHeader: View {
    let title: String
    var trailing: String?
    var trailingTone: SectionHeaderTrailingTone
    var systemImage: String?
    var uppercase: Bool
    var inset: Bool
    var variant: SectionHeaderVariant?

    private var legacyTrailingColor: Color?
    private var legacyHorizontalPadding: CGFloat?

    init(
        _ title: String,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        systemImage: String? = nil,
        uppercase: Bool = true,
        inset: Bool = true,
        variant: SectionHeaderVariant? = nil
    ) {
        self.title = title
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.systemImage = systemImage
        self.uppercase = uppercase
        self.inset = inset
        self.variant = variant
    }

    /// Pre-design-system API, kept so existing call sites compile until Phase 5.
    @_disfavoredOverload
    @available(*, deprecated, message: "Use SectionHeader(_:trailing:trailingTone:systemImage:uppercase:inset:variant:)")
    init(
        _ title: String,
        trailingText: String? = nil,
        trailingColor: Color? = nil,
        horizontalPadding: CGFloat = DS.Spacing.s4
    ) {
        self.init(title, trailing: trailingText, inset: false)
        self.legacyTrailingColor = trailingColor
        self.legacyHorizontalPadding = horizontalPadding
    }

    private var titleColor: Color {
        variant == .primary ? DS.Color.primaryText : DS.Color.textTertiary
    }

    private var trailingColor: Color {
        if let legacyTrailingColor { return legacyTrailingColor }
        return trailingTone == .primary ? DS.Color.primaryText : DS.Color.textTertiary
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s1_5) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(uppercase ? title.uppercased() : title)
                    .tracking(uppercase ? DS.TextStyle.sansXs.trackingWidest : 0)
            }
            .textStyle(.sansXs, tone: nil, weight: .semibold)
            .foregroundStyle(titleColor)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(title)

            Spacer(minLength: DS.Spacing.s2)

            if let trailing {
                Text(trailing)
                    .textStyle(inset ? .sansSm : .sansXs, tone: nil, numeric: true)
                    .foregroundStyle(trailingColor)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, legacyHorizontalPadding ?? (inset ? DS.Spacing.sectionInset : 0))
        .padding(.bottom, inset ? DS.Spacing.s2 : 0)
        .accessibilityElement(children: .combine)
    }
}

private struct SectionHeaderGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s5) {
            SectionHeader("Who rated", trailing: "5 of 6")
            SectionHeader("This recipe over time", trailing: "3 times", trailingTone: .primary)
            SectionHeader("Italian", inset: false)
            SectionHeader("Joel\u{2019}s note", uppercase: false, inset: false)
            SectionHeader("Household score", systemImage: "person.2", inset: false, variant: .primary)
        }
        .padding(DS.Spacing.s4)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { SectionHeaderGallery() }
#Preview("Dark") { SectionHeaderGallery().preferredColorScheme(.dark) }
