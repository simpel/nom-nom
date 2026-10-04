import SwiftUI

// Sheet chrome (AGENTS.md §5). The leading close is always an AppButton
// `secondary soft` icon-only xmark on `.topBarLeading`, alone; primary actions sit on
// `.topBarTrailing`. Implementations live in `View+SheetToolbarModifiers.swift`.

extension View {
    /// The BottomSheet presentation: `sheet` ground, `radius-4xl` top corners and the
    /// DS grabber (`spacing-10` × `spacing-1.5`, `radius-sm`, `grabber`, `spacing-2`
    /// from the top) in place of the system drag indicator. Apply to the sheet's root
    /// view; lay its content out with `SheetBody`. The scrim is the system dimming
    /// (DS-GAPS.md).
    func dsSheet(detents: Set<PresentationDetent> = [.large], pro: Bool = false) -> some View {
        self
            .overlay(alignment: .top) { SheetGrabber() }
            .presentationDetents(detents)
            .presentationDragIndicator(.hidden)
            .presentationBackground(pro ? DS.Color.proSoft : DS.Color.sheet)
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

    /// A pushed middle step of a multi-step sheet (it keeps the navigation back
    /// button): a trailing text action ("Next"), disabled until `canProceed`.
    /// DS-GAP: the multi-step toolbar convention is pending (DS-GAPS.md).
    func stepNextToolbar(
        title: String = "Next",
        canProceed: Bool = true,
        onNext: @escaping () -> Void
    ) -> some View {
        modifier(StepNextToolbarModifier(title: title, canProceed: canProceed, onNext: onNext))
    }

    /// Media viewers, photo lightboxes and read-only sheets: a leading close.
    func sheetCloseToolbar(
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
}

private struct DSSheetPreview: View {
    @State private var isPresented = true

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    SheetBody {
                        SheetHero(score: 1, lead: "16 above Joel\u{2019}s usual of 84", emphasis: "16 above")
                        SheetCard(
                            "Why Joel loved it",
                            provenance: "AI summary of Joel\u{2019}s 54 past ratings",
                            reasons: [SheetReason(title: "Crispy crust", text: "Wood-fired pizza is his favourite.")]
                        )
                    }
                    .screenTitle("Joel\u{2019}s score", displayMode: .inline)
                    .sheetCloseToolbar()
                }
                .dsSheet(detents: [.medium, .large])
            }
    }
}

#Preview("Light") { DSSheetPreview() }
#Preview("Dark") { DSSheetPreview().preferredColorScheme(.dark) }
