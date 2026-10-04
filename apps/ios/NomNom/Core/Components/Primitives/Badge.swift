import SwiftUI

/// Badge sizes (Badge README table): height and side padding. The label is always
/// `sans-xs` semibold and the icon `text-xs`, at both sizes.
enum BadgeSize: Equatable {
    case sm
    case md

    /// Minimum height, so the capsule grows with Dynamic Type instead of clipping.
    var height: CGFloat { self == .sm ? DS.Spacing.s5 : DS.Spacing.s6 }
    var horizontalPadding: CGFloat { self == .sm ? DS.Spacing.s2 : DS.Spacing.s2_5 }
}

/// Badge's subset of the appearances: "Outline and ghost are button appearances only."
enum BadgeAppearance: Equatable {
    /// `{role}-soft` + `{role}-text`: the default for everything.
    case soft
    /// `{role}` + `on-{role}`: the strongest step of an ordinal. Falls back to soft
    /// for `reaction` ("a reaction fill never carries text").
    case solid
    /// `panel` + `shadow-xs` + `{role}-text`: over photos and heroes. For `reaction`
    /// the ground is the step's fill at `opacity-15` over `panel`.
    case elevated
}

/// The one badge: a small capsule that labels or rates something. One word, one
/// number or one short phrase, never a number and a word together. Badges are never
/// tappable; a selectable pill is a `sm` AppButton.
///
/// A badge is a label the thing carries: something you would scan a list for and that
/// could be different tomorrow (a verdict, a rotation goal, Pro, Archived, New, a
/// signed change). A fact — a duration, a method, a cuisine, a date, a count — is a
/// `sans-sm` `text-tertiary` line joined with " · ", not a badge.
/// See `BadgeHelpers.swift` for the README recipes.
struct Badge: View {
    let text: String
    var icon: String?
    var iconPosition: DSIconPosition
    var variant: DSVariant
    var appearance: BadgeAppearance
    var size: BadgeSize
    /// The spec's `title`: a tooltip such as the score behind a verdict word.
    var tooltip: String?
    var accessibilityLabel: String?

    init(
        _ text: String,
        icon: String? = nil,
        iconPosition: DSIconPosition = .start,
        variant: DSVariant = .primary,
        appearance: BadgeAppearance = .soft,
        size: BadgeSize = .md,
        tooltip: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.text = text
        self.icon = icon
        self.iconPosition = iconPosition
        self.variant = variant
        self.appearance = appearance
        self.size = size
        self.tooltip = tooltip
        self.accessibilityLabel = accessibilityLabel
    }

    /// The appearance actually painted: a reaction is never solid.
    private var resolvedAppearance: BadgeAppearance {
        appearance == .solid && variant.isReaction ? .soft : appearance
    }

    private var foreground: Color {
        resolvedAppearance == .solid ? variant.role.on : variant.role.text
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s1) {
            if iconPosition == .end {
                label
                iconView
            } else {
                iconView
                label
            }
        }
        .textStyle(.sansXs, tone: nil, weight: .semibold, numeric: true, lines: 1)
        .foregroundStyle(foreground)
        .padding(.horizontal, size.horizontalPadding)
        .frame(minHeight: size.height)
        .background { ground }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel ?? text)
        .modifier(BadgeTooltip(tooltip: tooltip))
    }

    private var label: Text {
        Text(text)
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(systemName: icon).accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var ground: some View {
        let role = variant.role
        switch resolvedAppearance {
        case .solid:
            Capsule().fill(role.fill)
        case .elevated:
            Capsule()
                .fill(DS.Color.panel)
                .overlay {
                    if case .reaction(let reaction) = variant {
                        Capsule().fill(reaction.fill.opacity(DS.Opacity.reactionBadge))
                    }
                }
                .dsShadow(.xs)
        case .soft:
            Capsule().fill(role.soft)
        }
    }
}

private struct BadgeTooltip: ViewModifier {
    let tooltip: String?

    func body(content: Content) -> some View {
        if let tooltip {
            content.help(tooltip).accessibilityHint(tooltip)
        } else {
            content
        }
    }
}

private struct BadgeGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s2) {
                Badge.pro
                Badge("Archived", variant: .secondary)
                Badge("New", size: .sm)
            }
            HStack(spacing: DS.Spacing.s2) {
                ForEach(Reaction.allCases) { Badge.verdict($0, size: .sm) }
            }
            HStack(spacing: DS.Spacing.s2) {
                Badge.delta(16)
                Badge.delta(-2)
                Badge.delta(0)
                Badge.rank(3)
            }
            HStack(spacing: DS.Spacing.s2) {
                Badge("Cover", variant: .secondary, appearance: .elevated, size: .sm)
                Badge.verdict(score: 0.9, appearance: .elevated, size: .sm)
                Badge.verdict(score: 0.4, appearance: .elevated, size: .sm)
            }
            if let summary = DishSummary(reactions: [.great, .amazing], effort: .zeroTo15) {
                Badge.dishSummary(summary)
            }
        }
        .padding(DS.Spacing.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { BadgeGallery() }
#Preview("Dark") { BadgeGallery().preferredColorScheme(.dark) }
