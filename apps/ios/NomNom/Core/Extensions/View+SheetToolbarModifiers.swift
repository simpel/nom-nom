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

/// `.topBarLeading` close item: a system xmark on the bar's white glass circle, in
/// `text-primary` like every other top-bar control (`barItemStyle()`).
struct SheetLeadingCloseItem: ToolbarContent {
    let accessibilityLabel: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: action) {
                Image(systemName: "xmark").fontWeight(.semibold)
            }
            .accessibilityLabel(accessibilityLabel)
            .disabled(isDisabled)
            .barItemStyle()
        }
    }
}

struct StepNextToolbarModifier: ViewModifier {
    let title: String
    let canProceed: Bool
    let onNext: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(title, action: onNext)
                        .disabled(!canProceed)
                        .fontWeight(.semibold)
                        .barItemStyle()
                }
            }
    }
}

/// Inside a `.discardGuard` (the recipe scanner) the close asks first when there are changes.
struct SheetCloseToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editorSheetActions) private var editorSheet

    let accessibilityLabel: String
    let onClose: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                SheetLeadingCloseItem(accessibilityLabel: accessibilityLabel, isDisabled: editorSheet?.isSaving ?? false) {
                    if let onClose { onClose() } else if let editorSheet { editorSheet.close() } else { dismiss() }
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
                        .barItemStyle()
                    }
                }
            }
    }
}
