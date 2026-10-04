import SwiftUI

/// A Pro block inside a free view (`design-system/components/Pro/README.md`): rater
/// reasons, health detail, Recommended for you. A `pro-soft` card at `radius-3xl`,
/// `spacing-5` padding and `shadow-lg` (the only card that floats), the ProMark, a
/// `serif-sm` title and an optional `sans-xs` tertiary `sub` ("Based on Anna's 34 ratings").
///
/// Locked (no Pro): the `teaser` sentence, a blurred preview of the real `content` capped
/// at `spacing-28`, and "Unlock with Pro" (`pro solid lg`, full width, sparkles). Locked
/// never means empty. The blurred copy is hidden from VoiceOver.
///
/// `teaser` is optional: a screen whose title already says what the block holds can
/// leave it out (DS-GAPS B, "ProCard without a teaser").
///
/// `mark: false` drops the ProMark; use it inside a ProView, which is already marked.
/// A RecipeShelf inside runs edge to edge: pass `contentBleed: DS.Spacing.s5` and give the
/// shelf the same `bleed`.
struct ProCard<Content: View>: View {
    let title: String
    var sub: String?
    var teaser: String?
    var mark: Bool
    var contentBleed: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(EntitlementStore.self) private var entitlements
    @State private var showPaywall = false

    init(
        _ title: String,
        sub: String? = nil,
        teaser: String? = nil,
        mark: Bool = true,
        contentBleed: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.sub = sub
        self.teaser = teaser
        self.mark = mark
        self.contentBleed = contentBleed
        self.content = content
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                if mark { ProMark() }
                Text(title).textStyle(.serifSm).accessibilityAddTraits(.isHeader)
                if let sub {
                    Text(sub).textStyle(.sansXs, tone: .tertiary)
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
        .proPaywall(isPresented: $showPaywall)
    }

    private var locked: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            if let teaser {
                Text(teaser).textStyle(.sansMd, tone: .secondary)
            }
            content()
                .padding(.horizontal, -contentBleed)
                .frame(maxHeight: DS.Spacing.s28, alignment: .top)
                .clipped()
                .blur(radius: ProBlur.radius)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            AppButton("Unlock with Pro", icon: "sparkles", variant: .pro, size: .lg, fullWidth: true) {
                showPaywall = true
            }
        }
    }
}
