import SwiftUI

/// The one button: a capsule with a colour role (`variant`), a visual weight
/// (`appearance`) and a size. Disable with `.disabled(_:)`.
///
/// - `primary solid`: the one main commitment on a screen.
/// - `primary soft`: supporting branded actions.
/// - `secondary`: alternatives and utilities; `secondary soft` icon-only is the in-sheet close.
/// - `destructive`: irreversible actions only (prefer outline or ghost).
/// - `pro`: Nom Nom Pro CTAs only.
/// - `elevated` icon-only: floating controls over content.
struct AppButton: View {
    private let title: String?
    private let icon: AppButtonIcon?
    private let iconPosition: DSIconPosition
    private let variant: DSVariant
    private let appearance: DSAppearance
    private let size: AppButtonSize
    private let fullWidth: Bool
    private let isLoading: Bool
    private let isDisabled: Bool
    private let accessibilityLabel: String?
    private let action: () -> Void

    /// A labelled button.
    init(
        _ title: String,
        icon: AppButtonIcon? = nil,
        iconPosition: DSIconPosition = .start,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .solid,
        size: AppButtonSize = .md,
        fullWidth: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.variant = variant
        self.appearance = appearance
        self.size = size
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.isDisabled = false
        self.accessibilityLabel = nil
        self.action = action
    }

    /// A circular icon-only button; `accessibilityLabel` is its spoken name.
    init(
        icon: AppButtonIcon,
        accessibilityLabel: String,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .solid,
        size: AppButtonSize = .md,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = nil
        self.icon = icon
        self.iconPosition = .start
        self.variant = variant
        self.appearance = appearance
        self.size = size
        self.fullWidth = false
        self.isLoading = isLoading
        self.isDisabled = false
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    /// Pre-design-system API, kept so existing call sites compile until Phase 5.
    @_disfavoredOverload
    @available(*, deprecated, message: "Use AppButton(_:icon:iconPosition:variant:appearance:size:fullWidth:isLoading:action:)")
    init(
        _ title: String = "",
        icon: AppButtonIcon? = nil,
        systemImage: String? = nil,
        iconPosition: AppButtonIconPosition = .leading,
        variant: AppButtonVariant = .primary,
        style: AppButtonStyle = .normal,
        size: AppButtonSize = .md,
        isFullWidth: Bool = false,
        isPending: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        let axes = variant.dsAxes(style: style)
        self.title = title.isEmpty ? nil : title
        self.icon = icon ?? systemImage.map { .system($0) }
        self.iconPosition = iconPosition.dsPosition
        self.variant = axes.0
        self.appearance = axes.1
        self.size = size
        self.fullWidth = isFullWidth
        self.isLoading = isPending
        self.isDisabled = disabled
        self.accessibilityLabel = nil
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            AppButtonLabel(
                title,
                icon: icon,
                iconPosition: iconPosition,
                variant: variant,
                appearance: appearance,
                size: size,
                fullWidth: fullWidth,
                isLoading: isLoading,
                accessibilityLabel: accessibilityLabel
            )
        }
        .buttonStyle(AppPressableButtonStyle())
        .disabled(isDisabled || isLoading)
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}

#Preview {
    ScrollView {
        VStack(spacing: DS.Spacing.s3) {
            AppButton("Rate this meal", size: .lg, fullWidth: true) {}
            AppButton("Join dinner party", appearance: .soft) {}
            AppButton("Use a different address", variant: .secondary, appearance: .ghost) {}
            AppButton("Reset filters", variant: .secondary, appearance: .outline, size: .sm) {}
            AppButton("Delete meal", icon: "trash", variant: .destructive, appearance: .outline) {}
            AppButton("Unlock with Pro", icon: "sparkles", variant: .pro) {}
            AppButton("Next", icon: "arrow.right", iconPosition: .end, appearance: .soft) {}
            AppButton("Saving", isLoading: true) {}
            AppButton("Disabled") {}.disabled(true)
            HStack(spacing: DS.Spacing.s3) {
                AppButton(icon: "chevron.left", accessibilityLabel: "Back", variant: .secondary, appearance: .elevated) {}
                AppButton(icon: "xmark", accessibilityLabel: "Close", variant: .secondary, appearance: .soft, size: .sm) {}
                AppButton(icon: "plus", accessibilityLabel: "Add") {}
            }
        }
        .padding(DS.Spacing.s4)
    }
    .background(DS.Color.bg)
}

#Preview("Dark") {
    VStack(spacing: DS.Spacing.s3) {
        AppButton("Rate this meal", size: .lg, fullWidth: true) {}
        AppButton("Join dinner party", appearance: .soft) {}
        AppButton("Skip step", variant: .secondary, appearance: .soft) {}
        AppButton("Sign out", variant: .destructive, appearance: .ghost) {}
        AppButton(icon: "chevron.left", accessibilityLabel: "Back", variant: .secondary, appearance: .elevated) {}
    }
    .padding(DS.Spacing.s4)
    .background(DS.Color.bg)
    .preferredColorScheme(.dark)
}
