// DS-GAP: pending design system
import SwiftUI

/// A Nom Nom Pro block inside a screen or sheet, as drawn on the "Nom Nom iOS" canvas
/// (Recipes "Recommended for you", the rater, health and member sheets). The DS defines
/// no gate (DS-GAPS.md), so this is built from its tokens: a `pro-soft` card at
/// `radius-3xl` with `shadow-lg` and `spacing-5` padding, a "PRO" eyebrow (`sans-xs`
/// semibold, `tracking-widest`, `pro-text`, sparkles), a `serif-sm` title and an optional
/// `sans-xs` tertiary provenance line, then the content.
///
/// Locked: the `teaser` sentence (`sans-md` secondary), the content blurred and capped
/// at `spacing-28` (the canvas draws 120, which has no token), and "Unlock with Pro" (`pro solid lg`, full width), which opens the
/// paywall. The blurred copy is hidden from VoiceOver.
struct ProSection<Content: View>: View {
    let title: String
    var provenance: String?
    var teaser: String
    /// Content that bleeds to the card's edges (a RecipeShelf) passes the card padding.
    var contentBleed: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(EntitlementStore.self) private var entitlements
    @State private var showPaywall = false

    init(
        _ title: String,
        provenance: String? = nil,
        teaser: String,
        contentBleed: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.provenance = provenance
        self.teaser = teaser
        self.contentBleed = contentBleed
        self.content = content
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    /// No blur token exists; ProGate's call (`shadow-lg`'s blur, DS-GAPS.md).
    private static var contentBlur: CGFloat { DS.Shadow.lg.token.light[0].blur }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            ProEyebrow()
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(title).textStyle(.serifSm).accessibilityAddTraits(.isHeader)
                if let provenance {
                    Text(provenance).textStyle(.sansXs, tone: .tertiary)
                }
            }
            if entitlements.hasProAccess {
                content().padding(.horizontal, -contentBleed)
            } else {
                locked
            }
        }
        .padding(DS.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(DS.Color.proSoft))
        .dsShadow(.lg, in: shape)
        .sheet(isPresented: $showPaywall) {
            InsightsPaywallSheet(
                onPurchaseCompleted: { info in
                    entitlements.apply(info)
                    showPaywall = false
                },
                onRestoreCompleted: { info in
                    entitlements.apply(info)
                    showPaywall = false
                }
            )
        }
    }

    private var locked: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            Text(teaser).textStyle(.sansMd, tone: .secondary)
            content()
                .padding(.horizontal, -contentBleed)
                .frame(maxHeight: DS.Spacing.s28, alignment: .top)
                .clipped()
                .blur(radius: Self.contentBlur)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            AppButton("Unlock with Pro", icon: "sparkles", variant: .pro, size: .lg, fullWidth: true) {
                showPaywall = true
            }
        }
    }
}

/// The "PRO" overline on Pro blocks: sparkles + "Pro", `sans-xs` semibold uppercase,
/// `tracking-widest`, `pro-text`.
struct ProEyebrow: View {
    var body: some View {
        HStack(spacing: DS.Spacing.s1_5) {
            Image(systemName: "sparkles").accessibilityHidden(true)
            Text("Pro")
                .textCase(.uppercase)
                .tracking(DS.TextStyle.sansXs.trackingWidest)
        }
        .textStyle(.sansXs, weight: .semibold)
        .foregroundStyle(DS.Color.proText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nom Nom Pro")
    }
}
