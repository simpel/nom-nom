import SwiftUI

/// Badge sizes: height and side padding (label is always `sans-xs` semibold).
enum BadgeSize: Equatable {
    case sm
    case md

    var height: CGFloat { self == .sm ? DS.Spacing.s5 : DS.Spacing.s6 }
    var horizontalPadding: CGFloat { self == .sm ? DS.Spacing.s2 : DS.Spacing.s2_5 }
}

/// The one badge: a small capsule that labels or rates something. One word, one
/// number or one short phrase, never both. Badges are never tappable.
///
/// Appearances: `soft` (default), `solid` (strongest step of an ordinal; a reaction
/// falls back to soft) and `elevated` (over photos and heroes). Outline and ghost are
/// button-only and render as soft. See `BadgeHelpers.swift` for the recipes.
struct Badge: View {
    let text: String
    var icon: String?
    var iconPosition: DSIconPosition
    var variant: DSVariant
    var appearance: DSAppearance
    var size: BadgeSize
    var accessibilityLabel: String?

    init(
        _ text: String,
        icon: String? = nil,
        iconPosition: DSIconPosition = .start,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .soft,
        size: BadgeSize = .md,
        accessibilityLabel: String? = nil
    ) {
        self.text = text
        self.icon = icon
        self.iconPosition = iconPosition
        self.variant = variant
        self.appearance = appearance
        self.size = size
        self.accessibilityLabel = accessibilityLabel
    }

    /// The appearance actually painted: reaction never solid; outline/ghost → soft.
    private var resolvedAppearance: DSAppearance {
        switch appearance {
        case .solid: return variant.isReaction ? .soft : .solid
        case .elevated: return .elevated
        case .soft, .outline, .ghost: return .soft
        }
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
        .textStyle(.sansXs, tone: nil, weight: .semibold, numeric: true)
        .lineLimit(1)
        .foregroundStyle(foreground)
        .padding(.horizontal, size.horizontalPadding)
        .frame(minHeight: size.height)
        .background { ground }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel ?? text)
    }

    private var label: Text {
        Text(text).tracking(DS.TextStyle.sansXs.trackingWider)
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
        default:
            Capsule().fill(role.soft)
        }
    }
}

private struct BadgeGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s2) {
                Badge("Vegetarian", variant: .secondary, size: .sm)
                Badge("30 min", icon: "clock", size: .sm)
                Badge.pro
            }
            HStack(spacing: DS.Spacing.s2) {
                ForEach(RotationGoal.allCases) { Badge.rotation($0) }
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
                Badge("Mar 12", icon: "calendar", variant: .secondary, appearance: .elevated)
                Badge.verdict(score: 0.9, appearance: .elevated, size: .sm)
                Badge.verdict(score: 0.4, appearance: .elevated, size: .sm)
            }
            if let summary = DishSummary(reactions: [.great, .amazing], effort: .zeroTo15) {
                Badge.dishSummary(summary)
            }
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { BadgeGallery() }
#Preview("Dark") { BadgeGallery().preferredColorScheme(.dark) }
