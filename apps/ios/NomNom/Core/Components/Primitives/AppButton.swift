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
///
/// Every button is at least 44 × 44; icon-only buttons are one 44pt circle.
/// `isLoading` swaps the icon for a spinner and drops the action without disabling
/// the button (README: "A pending button keeps focus").
struct AppButton: View {
    private let label: AppButtonLabel
    private let isLoading: Bool
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
        self.label = AppButtonLabel(
            title, icon: icon, iconPosition: iconPosition, variant: variant, appearance: appearance,
            size: size, fullWidth: fullWidth, isLoading: isLoading
        )
        self.isLoading = isLoading
        self.action = action
    }

    /// A 44pt icon-only circle; `accessibilityLabel` is its spoken name. There is one
    /// icon-only size, so it takes none.
    init(
        icon: AppButtonIcon,
        accessibilityLabel: String,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .solid,
        isLoading: Bool = false,
        iconColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.label = AppButtonLabel(
            icon: icon, accessibilityLabel: accessibilityLabel, variant: variant,
            appearance: appearance, isLoading: isLoading, iconColor: iconColor
        )
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            guard !isLoading else { return }
            action()
        } label: {
            label
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}

private struct AppButtonGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s3) {
                AppButton("Rate this meal", size: .lg, fullWidth: true) {}
                AppButton("Join dinner party", appearance: .soft) {}
                AppButton("Use a different address", variant: .secondary, appearance: .ghost) {}
                AppButton("Reset filters", variant: .secondary, appearance: .outline, size: .sm) {}
                AppButton("Resend", variant: .secondary, appearance: .ghost, size: .xs) {}
                AppButton("Delete meal", icon: "trash", variant: .destructive, appearance: .outline) {}
                AppButton("Unlock with Pro", icon: "sparkles", variant: .pro) {}
                AppButton("Next", icon: "arrow.right", iconPosition: .end, appearance: .soft) {}
                AppButton("Saving", isLoading: true) {}
                AppButton("Disabled") {}.disabled(true)
                HStack(spacing: DS.Spacing.s3) {
                    AppButton(icon: "chevron.left", accessibilityLabel: "Back", variant: .secondary, appearance: .elevated) {}
                    AppButton(icon: "xmark", accessibilityLabel: "Close", variant: .secondary, appearance: .soft) {}
                    AppButton(icon: "plus", accessibilityLabel: "Add") {}
                }
            }
            .padding(DS.Spacing.gutter)
        }
        .background(DS.Color.bg)
    }
}

#Preview("Light") { AppButtonGallery() }
#Preview("Dark") { AppButtonGallery().preferredColorScheme(.dark) }
