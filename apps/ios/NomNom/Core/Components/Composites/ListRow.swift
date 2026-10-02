import SwiftUI

/// The one row (components/ListRow/README.md): a leading slot, a title with optional
/// meta, a tabular `value` or a `trailing` slot, and a chevron. Every list is this row
/// inside `Card(layout: .list)`, which draws the surface and the hairlines.
///
/// The shapes:
/// - **Navigation**: `title`, optional `meta`, `action` → chevron.
/// - **Key–value**: `title` + `value`, not pressable, no chevron.
/// - **Toggle**: `title` + `meta`, `trailing: .toggle($on)`, not pressable.
/// - **Subject**: `leading` Avatar or PhotoCard `xs`, name, date or count as meta,
///   `trailing` ScoreValue `xs` or a Badge.
/// - **Invite**: `leading` Avatar `sm`, the email, "Invited {when}", Resend
///   (`secondary ghost sm`) + `trailingAction` revoke ✕ (`destructive ghost` icon-only).
///
/// A pressable row with a control in its trailing slot **splits**: only the title
/// region is the button and the trailing slot is its sibling. A row wrapped in a
/// `NavigationLink` passes `chevron: true`, which also sets its title semibold.
///
/// ```swift
/// Card(layout: .list) {
///     ListRow("Elin", meta: "Tue 29 Sep", leading: .avatar(Avatar(name: "Elin", size: .sm)),
///             trailing: .score(0.83))
///     ListRow("Weekly digest", meta: "Every Sunday", trailing: .toggle($digest))
///     ListRow("Member since", value: "Mar 2026")
/// }
/// ```
struct ListRow: View {
    var title: String
    var meta: String?
    /// A coloured run after `meta` ("Fridays · " + "Waiting on 2" in `warning-text`).
    var metaAccent: ListRowMetaAccent?
    var value: String?
    var leading: ListRowLeading
    var trailing: ListRowTrailing?
    /// The second trailing element: a `ghost` icon-only AppButton.
    var trailingAction: ListRowIconAction?
    /// `nil` = shown when pressable.
    var chevron: Bool?
    /// A `primary` dot in the gutter and a semibold title. Never a tinted ground.
    var unread: Bool
    var tone: ListRowTone?
    var size: ListRowSize
    /// Accessible name for the pressable region when the title alone is not enough.
    var label: String?
    var action: (() -> Void)?
    private var customTitle: AnyView?

    init(
        _ title: String,
        meta: String? = nil,
        metaAccent: ListRowMetaAccent? = nil,
        value: String? = nil,
        leading: ListRowLeading = .none,
        trailing: ListRowTrailing? = nil,
        trailingAction: ListRowIconAction? = nil,
        chevron: Bool? = nil,
        unread: Bool = false,
        tone: ListRowTone? = nil,
        size: ListRowSize = .md,
        label: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.meta = meta
        self.metaAccent = metaAccent
        self.value = value
        self.leading = leading
        self.trailing = trailing
        self.trailingAction = trailingAction
        self.chevron = chevron
        self.unread = unread
        self.tone = tone
        self.size = size
        self.label = label
        self.action = action
    }

    /// A row whose title is not a plain string (a name and a role in two steps).
    /// `accessibilityTitle` names the setting for a Toggle and VoiceOver.
    init<Title: View>(
        accessibilityTitle: String,
        meta: String? = nil,
        leading: ListRowLeading = .none,
        trailing: ListRowTrailing? = nil,
        chevron: Bool? = nil,
        size: ListRowSize = .md,
        action: (() -> Void)? = nil,
        @ViewBuilder title: () -> Title
    ) {
        self.init(accessibilityTitle, meta: meta, leading: leading, trailing: trailing,
                  chevron: chevron, size: size, action: action)
        self.customTitle = AnyView(title())
    }

    private var isPressable: Bool { action != nil || chevron == true }
    private var showsChevron: Bool { chevron ?? (action != nil) }
    private var isSplit: Bool {
        action != nil && (trailing?.isInteractive == true || trailingAction != nil)
    }

    var body: some View {
        Group {
            if let action, isSplit {
                // bundle.css `.nn-row[data-split]`: the row's `spacing-3` gap plus the
                // trail's `spacing-3` left padding.
                HStack(spacing: DS.Spacing.s3) {
                    Button(action: action) { main.rowMetrics(size) }
                        .buttonStyle(ListRowButtonStyle())
                        .modifier(OptionalAccessibilityLabel(label: label))
                    trail.padding(.leading, DS.Spacing.s3)
                    chevronView
                }
            } else if let action {
                Button(action: action) { HStack(spacing: DS.Spacing.s3) { main; trail; chevronView }.rowMetrics(size) }
                    .buttonStyle(ListRowButtonStyle())
                    .modifier(OptionalAccessibilityLabel(label: label))
            } else {
                HStack(spacing: DS.Spacing.s3) { main; trail; chevronView }.rowMetrics(size)
            }
        }
        .overlay(alignment: .leading) {
            if unread {
                // bundle.css `.nn-row[data-unread]::before`: a `spacing-2` `primary` dot,
                // `spacing-3` into the gutter.
                Circle()
                    .fill(DS.Color.primary)
                    .frame(width: DS.Spacing.s2, height: DS.Spacing.s2)
                    .offset(x: -DS.Spacing.s3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityValue(unread ? "Unread" : "")
    }

    private var main: some View {
        HStack(spacing: DS.Spacing.s3) {
            ListRowLeadingView(slot: leading)
            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                titleView
                if let metaText {
                    metaText.textStyle(.sansSm, tone: .secondary, lines: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let value {
                // README: "right-aligned tabular value"; step and ink are unspecified.
                // RatingList's value rows (also ListRows) set `sans-sm` at full strength.
                Text(value).textStyle(.sansSm, numeric: true, lines: 1)
                    .layoutPriority(1)
            }
        }
    }

    private var metaText: Text? {
        let base = meta.flatMap { $0.isEmpty ? nil : Text($0) }
        guard let metaAccent else { return base }
        let accent = Text(metaAccent.text).foregroundStyle(metaAccent.color)
        return base.map { $0 + Text(" \u{00B7} ") + accent } ?? accent
    }

    @ViewBuilder
    private var titleView: some View {
        if let customTitle {
            customTitle.lineLimit(1)
        } else {
            Text(title)
                .textStyle(.sansMd, tone: nil, weight: isPressable || unread ? .semibold : nil, lines: 1)
                .foregroundStyle(tone == .destructive ? DS.Color.destructiveText : DS.Color.textPrimary)
        }
    }

    @ViewBuilder
    private var trail: some View {
        if trailing != nil || trailingAction != nil {
            HStack(spacing: DS.Spacing.s2) {
                if let trailing { ListRowTrailingView(slot: trailing, title: title) }
                if let trailingAction { trailingAction.button }
            }
            .layoutPriority(1)
        }
    }

    @ViewBuilder
    private var chevronView: some View {
        if showsChevron {
            // bundle.css `.nn-row__chevron`: `text-base`, `text-tertiary`.
            Image(systemName: "chevron.right")
                .textStyle(.sansMd, tone: .tertiary)
                .accessibilityHidden(true)
        }
    }
}

private extension View {
    /// bundle.css `.nn-row`: `spacing-3` vertical padding (`sm`: `spacing-2`) and a
    /// `spacing-14` (`sm`: `spacing-11`) minimum height.
    func rowMetrics(_ size: ListRowSize) -> some View {
        padding(.vertical, size.verticalPadding)
            .frame(maxWidth: .infinity, minHeight: size.minHeight, alignment: .leading)
            .contentShape(Rectangle())
    }
}

private struct OptionalAccessibilityLabel: ViewModifier {
    let label: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let label { content.accessibilityLabel(label) } else { content }
    }
}

/// A row's press (bundle.css `.nn-row[data-pressable]:active`): `opacity-70` and
/// `scale-press-row`. Pressable ListRows use it; give it to a `NavigationLink` that
/// wraps a ListRow.
struct ListRowButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? DS.Opacity.pressed : DS.Opacity.o100)
            .scaleEffect(configuration.isPressed && !reduceMotion ? DS.Motion.scalePressRow : 1)
            .animation(DS.Motion.press, value: configuration.isPressed)
    }
}
