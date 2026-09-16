import SwiftUI

extension View {
    /// Standard toolbar for form, editor, rating, and filter sheets.
    /// Includes a leading "Cancel" button to discard changes and a trailing checkmark button (or ProgressView) to save/confirm.
    /// Automatically disables interactive sheet dismissal when `isSaving` is true.
    func sheetCommitToolbar(
        isSaving: Bool = false,
        canSave: Bool = true,
        onCancel: (() -> Void)? = nil,
        onSave: @escaping () -> Void
    ) -> some View {
        modifier(SheetCommitToolbarModifier(
            isSaving: isSaving,
            canSave: canSave,
            onCancel: onCancel,
            onSave: onSave
        ))
    }

    /// Standard toolbar for media viewers, photo lightboxes, and read-only inspection sheets.
    /// Provides a leading `xmark` close button.
    func sheetCloseToolbar(
        color: Color = .primary,
        onClose: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetCloseToolbarModifier(color: color, onClose: onClose))
    }

    /// Standard toolbar for selection and entity pickers where item selection automatically dismisses.
    /// Provides a leading "Cancel" button to dismiss without selecting.
    func sheetCancelToolbar(
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetCancelToolbarModifier(onCancel: onCancel))
    }

    /// Standard toolbar for overview / list management sheets.
    /// Provides a leading `xmark` dismissal button (alone), with optional primary action (e.g., "+" create button) on trailing.
    func sheetOverviewToolbar(
        primarySystemImage: String? = nil,
        onPrimaryAction: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetOverviewToolbarModifier(
            primarySystemImage: primarySystemImage,
            onPrimaryAction: onPrimaryAction,
            onClose: onClose
        ))
    }

    /// Standard toolbar for overview / list management sheets (forwards to `sheetOverviewToolbar`).
    func sheetDoneToolbar(
        primarySystemImage: String? = nil,
        onPrimaryAction: (() -> Void)? = nil,
        onDone: (() -> Void)? = nil
    ) -> some View {
        sheetOverviewToolbar(
            primarySystemImage: primarySystemImage,
            onPrimaryAction: onPrimaryAction,
            onClose: onDone
        )
    }
}

private struct SheetCommitToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let isSaving: Bool
    let canSave: Bool
    let onCancel: (() -> Void)?
    let onSave: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let onCancel {
                            onCancel()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            onSave()
                        } label: {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                        .disabled(!canSave)
                        .accessibilityLabel("Save")
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
    }
}

private struct SheetCloseToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let color: Color
    let onClose: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(color)
                    }
                    .accessibilityLabel("Close")
                }
            }
    }
}

private struct SheetCancelToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let onCancel: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let onCancel {
                            onCancel()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Cancel")
                }
            }
    }
}

private struct SheetOverviewToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let primarySystemImage: String?
    let onPrimaryAction: (() -> Void)?
    let onClose: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Close")
                }

                if let primarySystemImage, let onPrimaryAction {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onPrimaryAction) {
                            Image(systemName: primarySystemImage)
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("Action")
                    }
                }
            }
    }
}
