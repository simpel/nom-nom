import SwiftUI
import UIKit

private struct ProGateContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat?
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() { value = next }
    }
}

/// Wraps any content in a Nom Nom Pro gate: renders the real, fully-computed `content`
/// blurred inside a Pro card with an "Unlock with Pro" button when the user isn't
/// entitled, or plain (plus a `Badge.pro` header when `showBadge`) when they are.
///
/// README "Colour": "Violet is Pro. `pro`, `pro-soft`, `pro-text`, `on-pro` mark Nom Nom
/// Pro (badges, gates, paywall) and nothing else"; tokens.json `pro-soft`: "gated-card
/// grounds". So the locked gate is a `pro-soft` card at `radius-3xl` — like every card,
/// no border and no shadow — and its bottom fades from clear into `pro-soft` under the
/// `pro solid` button. Used per section (not per card) so a free user sees one unlock
/// prompt per gated area.
///
/// When locked the gate is capped to the smaller of the content's natural height and half
/// the screen, so a tall gated section never pushes the prompt screens down. The fade
/// covers at most its last `spacing-48`.
///
/// `.accessibilityHidden` on the blurred content is load-bearing: `.blur()` alone does not
/// remove content from VoiceOver's tree.
struct ProGate<Content: View>: View {
    @Environment(EntitlementStore.self) private var entitlements
    var showBadge: Bool = false
    @State private var showPaywall = false
    @State private var measuredContentHeight: CGFloat?
    @ViewBuilder let content: () -> Content

    init(showBadge: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.showBadge = showBadge
        self.content = content
    }

    // TODO: remove — temporarily disables the Pro lock so every screen is reachable while
    // they're still being built. Flip back to `false` (or delete) once done.
    private let paywallDisabled = true

    private var isUnlocked: Bool { entitlements.isPro || paywallDisabled }

    /// No blur token exists; the content blurs by `shadow-lg`'s blur, the system's
    /// largest everyday blur (DS-GAPS.md, "core").
    private static var contentBlur: CGFloat { DS.Shadow.lg.token.light[0].blur }

    private var viewportHeight: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height
            ?? UIScreen.main.bounds.height
    }

    /// The gate's height while locked: the content's own height, capped at half the screen.
    private var lockedHeight: CGFloat {
        let maxAllowed = viewportHeight / 2
        return min(measuredContentHeight ?? maxAllowed, maxAllowed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        gatedStack
            .overlay(alignment: .topTrailing) {
                // Straddles the card's top edge, `spacing-4` in from the corner, its centre
                // on the edge. Outside the clip so the half above the card shows.
                if !isUnlocked && showBadge {
                    Badge.pro
                        .padding(.trailing, DS.Spacing.s4)
                        .alignmentGuide(.top) { $0.height / 2 }
                }
            }
            .onPreferenceChange(ProGateContentHeightKey.self) { measuredContentHeight = $0 }
            .animation(DS.Motion.layout, value: isUnlocked)
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
            if showBadge {
                VStack(alignment: .trailing, spacing: DS.Spacing.s2) {
                    Badge.pro
                        .padding(.trailing, DS.Spacing.gutter)
                    measuredContent
                }
            } else {
                measuredContent
            }
        } else {
            ZStack(alignment: .top) {
                measuredContent
                    .blur(radius: Self.contentBlur)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                lockOverlay
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Nom Nom Pro feature, locked")
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture { showPaywall = true }
            }
            .frame(height: lockedHeight, alignment: .top)
            .background(shape.fill(DS.Color.proSoft))
            .clipShape(shape)
        }
    }

    private var lockOverlay: some View {
        AppButton("Unlock with Pro", icon: "lock.fill", variant: .pro, appearance: .solid, size: .md) {
            showPaywall = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .bottom) {
            // Clear at the top so the blurred preview reads through, `pro-soft` (the
            // card's own ground) by the bottom so the button sits on solid ground.
            LinearGradient(colors: [.clear, DS.Color.proSoft], startPoint: .top, endPoint: .bottom)
                .frame(height: min(DS.Spacing.s48, lockedHeight))
                .allowsHitTesting(false)
        }
    }
}
