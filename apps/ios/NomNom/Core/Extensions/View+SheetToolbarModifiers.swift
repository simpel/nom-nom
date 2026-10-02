import SwiftUI

// Implementations behind the sheet toolbar modifiers in `View+SheetToolbars.swift`.

/// The BottomSheet grabber (bundle.css `.nn-sheet__grabber`): `spacing-10` ×
/// `spacing-1.5`, `radius-sm`, `grabber`, `spacing-2` below the sheet's top edge.
/// Decorative (README: "The sheet grabber is decorative"), so hidden from VoiceOver.
struct SheetGrabber: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
            .fill(DS.Color.grabber)
            .frame(width: DS.Spacing.s10, height: DS.Spacing.s1_5)
            .padding(.top, DS.Spacing.s2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The in-sheet close: AppButton `secondary soft` icon-only xmark (44pt circle).
struct SheetCloseButton: View {
    var accessibilityLabel: String = "Close"
    let action: () -> Void

    var body: some View {
        AppButton(
            icon: "xmark",
            accessibilityLabel: accessibilityLabel,
            variant: .secondary,
            appearance: .soft,
            action: action
        )
    }
}

/// `.topBarLeading` close item. On iOS 26 the bar's shared glass is hidden so the
/// AppButton capsule is the only ground.
private struct SheetLeadingCloseItem: ToolbarContent {
    let accessibilityLabel: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) { button }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { button }
        }
    }

    private var button: some View {
        SheetCloseButton(accessibilityLabel: accessibilityLabel, action: action)
            .disabled(isDisabled)
    }
}

/// `.topBarTrailing` checkmark, or a small spinner while saving.
private struct SheetSaveItem: ToolbarContent {
    let isSaving: Bool
    let canSave: Bool
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if isSaving {
                ProgressView().controlSize(.small)
            } else {
                Button(action: onSave) {
                    Image(systemName: "checkmark").fontWeight(.semibold)
                }
                .disabled(!canSave)
                .accessibilityLabel("Save")
            }
        }
    }
}

struct SheetCommitToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let isSaving: Bool
    let canSave: Bool
    let onCancel: (() -> Void)?
    let onSave: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetLeadingCloseItem(accessibilityLabel: "Cancel", isDisabled: isSaving) {
                    if let onCancel { onCancel() } else { dismiss() }
                }
                SheetSaveItem(isSaving: isSaving, canSave: canSave, onSave: onSave)
            }
            .interactiveDismissDisabled(isSaving)
    }
}

struct SheetNextToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let canProceed: Bool
    let onCancel: (() -> Void)?
    let onNext: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetLeadingCloseItem(accessibilityLabel: "Cancel") {
                    if let onCancel { onCancel() } else { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(title, action: onNext)
                        .disabled(!canProceed)
                        .fontWeight(.semibold)
                }
            }
    }
}

struct StepCommitToolbarModifier: ViewModifier {
    let isSaving: Bool
    let canSave: Bool
    let onSave: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetSaveItem(isSaving: isSaving, canSave: canSave, onSave: onSave)
            }
            .interactiveDismissDisabled(isSaving)
    }
}

struct SheetCloseToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let accessibilityLabel: String
    let onClose: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetLeadingCloseItem(accessibilityLabel: accessibilityLabel) {
                    if let onClose { onClose() } else { dismiss() }
                }
            }
    }
}

struct SheetOverviewToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let primarySystemImage: String?
    let onPrimaryAction: (() -> Void)?
    let onClose: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetLeadingCloseItem(accessibilityLabel: "Close") {
                    if let onClose { onClose() } else { dismiss() }
                }
                if let primarySystemImage, let onPrimaryAction {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onPrimaryAction) {
                            Image(systemName: primarySystemImage).fontWeight(.semibold)
                        }
                        .accessibilityLabel("Action")
                    }
                }
            }
    }
}
