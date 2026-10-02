import SwiftUI

/// A Pro-only view for someone without Pro (`design-system/components/Pro/README.md`,
/// ProGate): the real `content` blurred and at `opacity-60`, and over it a `panel` card at
/// `radius-3xl` with `shadow-xl`: the ProMark, a `serif-md` title ("Insights are part of
/// Nom Nom Pro"), one sentence, up to four checked benefits, "Unlock with Pro"
/// (`pro solid lg`, full width, sparkles) and a ghost "Not now" when `onDismiss` is given.
///
/// With Pro the gate is just `content`. Put it around the whole view (a ProView), not
/// around a block inside a free view: that is a locked ProCard.
///
/// `.accessibilityHidden` on the blurred content is load-bearing: `.blur()` alone does not
/// remove content from VoiceOver's tree.
struct ProGate<Content: View>: View {
    let title: String
    var message: String?
    var benefits: [String]
    var onDismiss: (() -> Void)?
    @ViewBuilder let content: () -> Content

    @Environment(EntitlementStore.self) private var entitlements
    @State private var showPaywall = false

    init(
        _ title: String,
        message: String? = nil,
        benefits: [String] = [],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.message = message
        self.benefits = benefits
        self.onDismiss = onDismiss
        self.content = content
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.xl3, style: .continuous)
    }

    var body: some View {
        if entitlements.hasProAccess {
            content()
        } else {
            content()
                .blur(radius: ProBlur.radius)
                .opacity(DS.Opacity.o60)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .overlay(alignment: .top) { panel }
                .proPaywall(isPresented: $showPaywall)
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                ProMark()
                Text(title).textStyle(.serifMd).accessibilityAddTraits(.isHeader)
                if let message {
                    Text(message).textStyle(.sansMd, tone: .secondary)
                }
            }
            if !benefits.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s2_5) {
                    ForEach(benefits.prefix(4), id: \.self) { benefit in
                        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s2_5) {
                            Image(systemName: "checkmark")
                                .textStyle(.sansSm, weight: .semibold)
                                .foregroundStyle(DS.Color.proText)
                                .accessibilityHidden(true)
                            Text(benefit).textStyle(.sansMd)
                        }
                    }
                }
            }
            VStack(spacing: DS.Spacing.s1) {
                AppButton("Unlock with Pro", icon: "sparkles", variant: .pro, size: .lg, fullWidth: true) {
                    showPaywall = true
                }
                if let onDismiss {
                    AppButton("Not now", variant: .secondary, appearance: .ghost, size: .lg, fullWidth: true) {
                        onDismiss()
                    }
                }
            }
        }
        .padding(DS.Spacing.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(DS.Color.panel))
        .dsShadow(.xl, in: shape)
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.s6)
    }
}
