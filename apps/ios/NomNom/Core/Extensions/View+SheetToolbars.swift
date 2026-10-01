import SwiftUI

// Sheet chrome (AGENTS.md §5). The leading close is always an AppButton
// `secondary soft sm` xmark on `.topBarLeading`, alone; primary actions sit on
// `.topBarTrailing`. Implementations live in `View+SheetToolbarModifiers.swift`.

extension View {
    /// The BottomSheet presentation: `sheet` ground, `radius-4xl` corners and a
    /// visible grabber. Apply inside the sheet's content.
    func dsSheet(detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground(DS.Color.sheet)
            .presentationCornerRadius(DS.Radius.xl4)
    }

    /// Form, editor, rating and filter sheets: leading close (discards the draft)
    /// and a trailing checkmark (or a spinner while saving). Interactive dismissal
    /// is disabled while `isSaving`.
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

    /// The first step of a multi-step sheet: leading close and a trailing text
    /// action ("Next") that is disabled until `canProceed`.
    func sheetNextToolbar(
        title: String = "Next",
        canProceed: Bool = true,
        onCancel: (() -> Void)? = nil,
        onNext: @escaping () -> Void
    ) -> some View {
        modifier(SheetNextToolbarModifier(
            title: title,
            canProceed: canProceed,
            onCancel: onCancel,
            onNext: onNext
        ))
    }

    /// A pushed later step of a multi-step sheet (it keeps the navigation back
    /// button): a trailing checkmark, or a spinner while saving. Interactive
    /// dismissal is disabled while `isSaving`.
    func stepCommitToolbar(
        isSaving: Bool = false,
        canSave: Bool = true,
        onSave: @escaping () -> Void
    ) -> some View {
        modifier(StepCommitToolbarModifier(isSaving: isSaving, canSave: canSave, onSave: onSave))
    }

    /// Media viewers, photo lightboxes and read-only sheets: a leading close.
    /// `color` is ignored now that the close is an AppButton; kept for call sites.
    func sheetCloseToolbar(
        color: Color = .primary,
        onClose: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetCloseToolbarModifier(accessibilityLabel: "Close", onClose: onClose))
    }

    /// Pickers where choosing an item dismisses: a leading close only.
    func sheetCancelToolbar(
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetCloseToolbarModifier(accessibilityLabel: "Cancel", onClose: onCancel))
    }

    /// Overview and list-management sheets: a leading close and an optional
    /// trailing primary action (e.g. "plus").
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

    /// Forwards to `sheetOverviewToolbar`.
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

private struct DSSheetPreview: View {
    @State private var isPresented = true

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    VStack(spacing: DS.Spacing.s6) {
                        SheetHero(score: 1, lead: "16 above Joel\u{2019}s usual of 84", emphasis: "16 above")
                        SheetCard(
                            "Why Joel loved it",
                            provenance: "AI summary of Joel\u{2019}s 54 past ratings",
                            reasons: [SheetReason(title: "Crispy crust", text: "Wood-fired pizza is his favourite.")]
                        )
                        Spacer()
                    }
                    .padding(.horizontal, DS.Spacing.s5)
                    .screenTitle("Joel\u{2019}s score", displayMode: .inline)
                    .sheetNextToolbar(canProceed: true) {}
                }
                .dsSheet(detents: [.medium, .large])
            }
    }
}

#Preview("Light") { DSSheetPreview() }
#Preview("Dark") { DSSheetPreview().preferredColorScheme(.dark) }
