import SwiftUI

/// PageHeader `align`: `center` only for the full-screen moments (sign-in, onboarding,
/// paywall); in-app screens and tab roots are `start`.
enum PageHeaderAlign: Equatable { case start, center }

/// PageHeader `size`: `sm` drops the title to `serif-md` and the actions to `md`.
enum PageHeaderSize: Equatable { case sm, md }

/// The title block of a screen with no subject (components/PageHeader/README.md). A
/// screen about a meal, recipe, party or person uses DetailHeader instead.
///
/// - Title: the screen's one heading, `serif-lg` (`serif-md` at `sm`).
/// - Subtitle: one sentence, `sans-md` `text-secondary`, capped at `container-sm`.
/// - Eyebrow: an uppercase SectionHeader above the title.
/// - Actions: at most two; the first `solid`, the rest `ghost`; `lg` (`md` at `sm`);
///   stacked full width when centred.
/// - Spacing: `spacing-2` between the parts, `spacing-4` more before the actions.
/// - `content`: anything under the block (a form, a package list).
///
/// ```swift
/// PageHeader("What did you eat tonight?",
///            subtitle: "Log it now and rate it when everyone has finished.")
/// PageHeader("Cook with the whole picture", eyebrow: "Nom Nom Pro", align: .center,
///            actions: [EmptyStateAction("Try Pro free", variant: .pro) { start() },
///                      EmptyStateAction("Not now") { dismiss() }])
/// ```
struct PageHeader<Content: View>: View {
    let title: String
    var subtitle: String?
    var eyebrow: String?
    var actions: [EmptyStateAction]
    var align: PageHeaderAlign
    var size: PageHeaderSize
    @ViewBuilder var content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        eyebrow: String? = nil,
        align: PageHeaderAlign = .start,
        size: PageHeaderSize = .md,
        actions: [EmptyStateAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.eyebrow = eyebrow
        self.actions = Array(actions.prefix(2))
        self.align = align
        self.size = size
        self.content = content()
    }

    private var horizontal: HorizontalAlignment { align == .center ? .center : .leading }
    private var frameAlignment: Alignment { align == .center ? .center : .leading }
    private var textAlign: TextAlignment { align == .center ? .center : .leading }

    var body: some View {
        VStack(alignment: horizontal, spacing: DS.Spacing.s2) {
            if let eyebrow {
                SectionHeader(title: eyebrow)
                    .fixedSize(horizontal: align == .center, vertical: false)
            }
            Text(title)
                .textStyle(size == .sm ? .serifMd : .serifLg, align: textAlign)
                .accessibilityAddTraits(.isHeader)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .textStyle(.sansMd, tone: .secondary, align: textAlign)
                    .frame(maxWidth: DS.Container.sm, alignment: frameAlignment)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !actions.isEmpty {
                actionButtons
                    // bundle.css `.nn-pagehead__actions { margin-top: spacing-4 }`.
                    .padding(.top, DS.Spacing.s4)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if align == .center {
            VStack(spacing: DS.Spacing.s2) { buttons(fullWidth: true) }
                .frame(maxWidth: DS.Container.sm)
        } else {
            HStack(spacing: DS.Spacing.s2) { buttons(fullWidth: false) }
        }
    }

    private func buttons(fullWidth: Bool) -> some View {
        ForEach(actions.indices, id: \.self) { index in
            let action = actions[index]
            AppButton(
                action.label,
                icon: action.icon,
                variant: action.variant ?? .primary,
                appearance: index == 0 ? .solid : .ghost,
                size: size == .sm ? .md : .lg,
                fullWidth: fullWidth,
                action: action.perform
            )
        }
    }
}

extension PageHeader where Content == EmptyView {
    init(
        _ title: String,
        subtitle: String? = nil,
        eyebrow: String? = nil,
        align: PageHeaderAlign = .start,
        size: PageHeaderSize = .md,
        actions: [EmptyStateAction] = []
    ) {
        self.init(title, subtitle: subtitle, eyebrow: eyebrow, align: align, size: size,
                  actions: actions) { EmptyView() }
    }
}

private struct PageHeaderGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.block) {
                PageHeader("Meals", actions: [EmptyStateAction("Add meal", icon: "plus") {}])
                PageHeader("What did you eat tonight?",
                           subtitle: "Log it now and rate it when everyone has finished.", size: .sm)
                PageHeader("Cook with the whole picture", subtitle: "Trends, party scores and unlimited photos.",
                           eyebrow: "Nom Nom Pro", align: .center,
                           actions: [EmptyStateAction("Try Pro free", variant: .pro) {}, EmptyStateAction("Not now") {}])
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { PageHeaderGallery() }
#Preview("Dark") { PageHeaderGallery().preferredColorScheme(.dark) }
