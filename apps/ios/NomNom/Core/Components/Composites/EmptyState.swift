import SwiftUI

/// EmptyState `layout` (components/EmptyState/README.md).
enum EmptyStateLayout: Equatable {
    /// The whole view has nothing: `serif-md`, centred vertically, `primary solid md`.
    case screen
    /// A block on a screen with other content: `serif-sm`, centred, in a Card, `primary soft sm`.
    case card
    /// Inside a Card or sheet that already draws the surface: `serif-sm`, left.
    case plain
    /// One line inside `Card(layout: .list)`: `sans-sm` tertiary, no message, button pushed right.
    case row
}

/// An AppButton an EmptyState (or PageHeader) builds. `variant` overrides the role the
/// layout picks: `.pro` for an upgrade, `.secondary` to soften.
struct EmptyStateAction {
    let label: String
    var icon: AppButtonIcon?
    var variant: DSVariant?
    let perform: () -> Void

    init(_ label: String, icon: AppButtonIcon? = nil, variant: DSVariant? = nil, perform: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.variant = variant
        self.perform = perform
    }
}

/// Nothing here yet: one fact, one sentence, at most one way out. No artwork; the
/// optional `icon` is one decorative `text-tertiary` glyph. Never use it for an error,
/// offline or loading state, and never as "None" in an empty list.
///
/// ```swift
/// EmptyState("No meals yet", message: "Log tonight\u{2019}s dinner and it will show up here.",
///            icon: "fork.knife", layout: .screen,
///            action: EmptyStateAction("Log a meal") { showEditor = true })
/// Card(layout: .list) {
///     EmptyState("No photo yet", icon: "camera", layout: .row,
///                action: EmptyStateAction("Add photo") { add() })
/// }
/// ```
struct EmptyState: View {
    let title: String
    var message: String?
    var icon: String?
    var layout: EmptyStateLayout
    var action: EmptyStateAction?
    var secondaryAction: EmptyStateAction?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        _ title: String,
        message: String? = nil,
        icon: String? = nil,
        layout: EmptyStateLayout = .card,
        action: EmptyStateAction? = nil,
        secondaryAction: EmptyStateAction? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.layout = layout
        self.action = action
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        switch layout {
        case .screen:
            // bundle.css `[data-layout="screen"]`: gap `spacing-3`, padding `spacing-12`
            // `spacing-5`, at least `spacing-72` tall, centred.
            stack(alignment: .center, gap: DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s12)
                .padding(.horizontal, DS.Spacing.s5)
                .frame(maxWidth: .infinity, minHeight: DS.Spacing.s72)
        case .card:
            // bundle.css `[data-layout="card"]`: a Card padded `spacing-8` `spacing-5`.
            // Card draws `spacing-5`; the extra `spacing-3` above and below makes `spacing-8`.
            Card {
                stack(alignment: .center, gap: DS.Spacing.s2)
                    .padding(.vertical, DS.Spacing.s3)
                    .frame(maxWidth: .infinity)
            }
        case .plain:
            stack(alignment: .leading, gap: DS.Spacing.s2)
                .padding(.vertical, DS.Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .row:
            row
        }
    }

    private func stack(alignment: HorizontalAlignment, gap: CGFloat) -> some View {
        let textAlign: TextAlignment = alignment == .center ? .center : .leading
        return VStack(alignment: alignment, spacing: gap) {
            if let icon { glyph(icon, step: layout == .screen ? .serifLg : .serifMd) }
            Text(title)
                .textStyle(layout == .screen ? .serifMd : .serifSm, align: textAlign)
                .accessibilityAddTraits(.isHeader)
            if let message, !message.isEmpty {
                // bundle.css `.nn-empty > p { max-width: container-sm }`.
                Text(message)
                    .textStyle(.sansMd, tone: .secondary, align: textAlign)
                    .frame(maxWidth: DS.Container.sm, alignment: alignment == .center ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if action != nil || secondaryAction != nil {
                // bundle.css `.nn-empty__actions`: wraps, `spacing-2` apart, `spacing-2` above.
                HStack(spacing: DS.Spacing.s2) { buttons }
                    .padding(.top, DS.Spacing.s2)
            }
        }
    }

    private var row: some View {
        // bundle.css `[data-layout="row"]`: gap `spacing-2`, padding `spacing-3`,
        // at least `spacing-14`, the button pushed right.
        HStack(spacing: DS.Spacing.s2) {
            if let icon { glyph(icon, step: .sansMd) }
            Text(title).textStyle(.sansSm, tone: .tertiary)
            Spacer(minLength: 0)
            buttons
        }
        .padding(.vertical, DS.Spacing.s3)
        .frame(maxWidth: .infinity, minHeight: DS.Spacing.rowMin, alignment: .leading)
    }

    /// bundle.css `.nn-empty__icon`: `text-3xl` (`screen`: `text-4xl`, `row`: `text-base`),
    /// `text-tertiary`. Those font sizes are the `serif-md`, `serif-lg` and `sans-md` steps.
    private func glyph(_ name: String, step: DS.TextStyle) -> some View {
        Image(systemName: name)
            .font(.system(size: step.scaledSize(dynamicTypeSize)))
            .foregroundStyle(DS.Color.textTertiary)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var buttons: some View {
        if let action {
            AppButton(action.label, icon: action.icon, variant: action.variant ?? .primary,
                      appearance: layout == .screen ? .solid : .soft,
                      size: layout == .screen ? .md : .sm, action: action.perform)
        }
        if let secondaryAction {
            // README: "secondary `ghost`" (a second, quieter way out).
            AppButton(secondaryAction.label, icon: secondaryAction.icon,
                      variant: secondaryAction.variant ?? .secondary, appearance: .ghost,
                      size: layout == .screen ? .md : .sm, action: secondaryAction.perform)
        }
    }
}
