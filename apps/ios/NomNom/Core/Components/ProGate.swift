import SwiftUI
import UIKit

private struct ProGateContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat?
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() { value = next }
    }
}

/// Wraps any content in a Nom Nom Pro gate: renders the real, fully-computed `content`
/// blurred behind a bordered, Pro-violet card with a lock + "Unlock with Pro" overlay when
/// the user isn't entitled, or plain (plus a `ProBadge` header) when they are. The locked
/// card is deliberately loud — solid `proSoft` fill, a `proBorder` outline, and a soft
/// shadow — so a gated section reads as "premium content lives here" rather than a
/// disabled/broken area. That violet role is reserved for Pro identity only; it's never
/// reused for ordinary emphasis, so it stays legible as one unambiguous signal. Used
/// per-section (not per-card) so a free user sees one unlock prompt per gated area, not a
/// stack of them.
///
/// The content can be any height. When locked, the gate itself is capped to the smaller of
/// the content's natural height and half the screen height, so a tall gated section (e.g. a
/// whole Insights screen) never pushes the lock prompt several screens down. The fade and the
/// lock message scale with whatever height that ends up being: the gradient covers at most
/// its last 200pt, and the icon + button are centered in the gate regardless of its height.
///
/// `.accessibilityHidden` on the blurred content is load-bearing: `.blur()` alone does not
/// remove content from VoiceOver's tree, so without it a free user could still have locked
/// data read aloud.
struct ProGate<Content: View>: View {
    @Environment(EntitlementStore.self) private var entitlements
    @State private var showPaywall = false
    @State private var measuredContentHeight: CGFloat?
    @ViewBuilder let content: () -> Content

    // TODO: remove — temporarily disables the Pro lock so every screen is reachable while
    // they're still being built. Flip back to `false` (or delete) once done.
    private let paywallDisabled = true

    private var isUnlocked: Bool { entitlements.isPro || paywallDisabled }

    private let gradientMaxHeight: CGFloat = 200

    private var viewportHeight: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height
            ?? UIScreen.main.bounds.height
    }

    /// The gate's height while locked: the content's own height, capped at half the screen.
    private var lockedHeight: CGFloat {
        let maxAllowed = viewportHeight / 2
        return min(measuredContentHeight ?? maxAllowed, maxAllowed)
    }

    var body: some View {
        gatedStack
            .modifier(LockedHeightCap(isLocked: !isUnlocked, height: lockedHeight))
            .overlay(alignment: .topTrailing) {
                // Straddles the card's top border rather than sitting inside it, so the
                // border reads as "PRO" is pinned to it. Inset from the corner (not flush)
                // and offset up by half its own height so its vertical center lands exactly
                // on the 1px border line. Applied outside `LockedHeightCap` so its clip
                // doesn't cut the half that pokes above the card.
                if !isUnlocked {
                    ProBadge(size: .compact)
                        .padding(.trailing, DS.Spacing.md)
                        .alignmentGuide(.top) { $0.height / 2 }
                }
            }
            .onPreferenceChange(ProGateContentHeightKey.self) { measuredContentHeight = $0 }
            .animation(.easeOut(duration: 0.2), value: isUnlocked)
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

    /// `content()` with its height published for `lockedHeight` to read, regardless of
    /// lock state (unlocking never has to wait on a stale measurement).
    private var measuredContent: some View {
        content()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ProGateContentHeightKey.self, value: proxy.size.height)
                }
            )
    }

    @ViewBuilder
    private var gatedStack: some View {
        if isUnlocked {
            // A header row, not an overlay: content is arbitrary height/shape, so pinning
            // the badge on top of it (as before) could land it mid-paragraph. Stacking it
            // above guarantees it never collides with whatever the content draws.
            VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
                ProBadge(size: .compact)
                measuredContent
            }
        } else {
            ZStack(alignment: .top) {
                measuredContent
                    .blur(radius: 14)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                lockOverlay
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Nom Nom Pro feature, locked")
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture { showPaywall = true }
            }
            .modifier(ProTeaserFrame(isLocked: true))
        }
    }

    private var lockOverlay: some View {
        AppButton("Unlock with Pro", systemImage: "lock.fill", variant: .pro, style: .normal, size: .md) {
            showPaywall = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .bottom) {
            unlockGradient
                .frame(height: min(gradientMaxHeight, lockedHeight))
        }
    }

    /// Fully transparent at the top so the blurred preview reads through, opaque by the
    /// bottom so the "Unlock with Pro" button sits on solid ground. Fades into `proSoft` (the
    /// teaser card's own fill) rather than the page background, so the gradient reads as part
    /// of the same bordered card instead of a seam. Capped at `gradientMaxHeight` so it stays
    /// a bottom-edge fade even when the gate is tall.
    private var unlockGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: DS.Color.Pro.proSoft.opacity(0.94), location: 0.55),
                .init(color: DS.Color.Pro.proSoft, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

/// Locked state gets a loud, bordered "premium content" frame in the Pro violet role —
/// never `accent` — so a gated section reads as categorically different from ordinary
/// emphasized UI, not just "extra important". Unlocked content is left untouched so
/// `ProGate` never clips or reshapes arbitrary Pro content it doesn't own.
private struct ProTeaserFrame: ViewModifier {
    let isLocked: Bool

    func body(content: Content) -> some View {
        if isLocked {
            content
                .background(
                    // Tint, not a solid fill — fades to `panel` (not literal white) so it
                    // still reads correctly in dark mode. Angled corner-to-corner but ending
                    // short of the exact bottom-right corner ("near" it) per design spec.
                    LinearGradient(
                        colors: [DS.Color.Pro.proAccent.opacity(0.3), DS.Color.panel],
                        startPoint: .topLeading,
                        endPoint: UnitPoint(x: 0.85, y: 0.9)
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(DS.Color.Pro.proAccent, lineWidth: 1)
                }
                .shadow(color: DS.Color.Pro.proAccent.opacity(0.16), radius: 20, x: 0, y: 8)
        } else {
            content
        }
    }
}

/// Applies the locked-state height cap + rounded clip, or leaves the view untouched when
/// unlocked (natural size, no clipping).
private struct LockedHeightCap: ViewModifier {
    let isLocked: Bool
    let height: CGFloat

    func body(content: Content) -> some View {
        if isLocked {
            content
                .frame(height: height, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        } else {
            content
        }
    }
}
