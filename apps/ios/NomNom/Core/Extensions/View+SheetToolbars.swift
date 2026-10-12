import SwiftUI

// Sheet chrome (AGENTS.md §5). The leading close is a system xmark on `.topBarLeading`,
// alone; primary actions sit on `.topBarTrailing`. Edit sheets take a `FormSession` and
// sit behind `.editorSheet` (`View+EditorSheet.swift`); the commit and "Next" toolbars
// can't be used without one. Implementations live in `View+SheetToolbarModifiers.swift`
// and `View+SheetCommitToolbars.swift`.

extension View {
    /// The BottomSheet presentation: `sheet` ground, `radius-4xl` top corners and the
    /// DS grabber (`spacing-10` × `spacing-1.5`, `radius-sm`, `grabber`, `spacing-2`
    /// from the top) in place of the system drag indicator. Apply to the sheet's root
    /// view; lay its content out with `SheetBody`. The scrim is the system dimming
    /// (DS-GAPS.md). Pass `selection` to drive the detent (a sheet sized to its content).
    func dsSheet(
        detents: Set<PresentationDetent> = [.large],
        selection: Binding<PresentationDetent>? = nil,
        pro: Bool = false
    ) -> some View {
        self
            .overlay(alignment: .top) { SheetGrabber() }
            .modifier(SheetDetents(detents: detents, selection: selection))
            .presentationDragIndicator(.hidden)
            .presentationBackground(pro ? DS.Color.proSoft : DS.Color.sheet)
            .presentationCornerRadius(DS.Radius.xl4)
            .environment(\.isProSheet, pro)
    }

    /// Form, editor, rating and filter sheets: leading close and a trailing checkmark
    /// (a spinner while saving), enabled by `session.canCommit`. Close asks "Discard
    /// changes?" when the form changed. The checkmark closes an unchanged edit as is;
    /// otherwise it runs `save` through `session.save` and closes the whole sheet when it
    /// succeeds. Needs `.editorSheet(session)` on the sheet's NavigationStack.
    func sheetCommitToolbar<Form: SheetForm>(
        _ session: FormSession<Form>,
        save: @escaping (Form) async throws -> Void
    ) -> some View {
        modifier(SessionCommitToolbarModifier(session: session, title: nil, showsClose: true, save: save))
    }

    /// The first step of a multi-step sheet: leading close (asks first when the form
    /// changed) and a trailing text action ("Next") that is disabled until `canProceed`.
    /// Needs `.editorSheet(session)` on the sheet's NavigationStack.
    func sheetNextToolbar<Form: SheetForm>(
        _ session: FormSession<Form>,
        title: String = "Next",
        canProceed: Bool,
        onNext: @escaping () -> Void
    ) -> some View {
        modifier(SessionNextToolbarModifier(session: session, title: title, canProceed: canProceed, onNext: onNext))
    }

    /// A pushed last step of a multi-step sheet (it keeps the navigation back button): a
    /// trailing checkmark, or a spinner while saving, that works like
    /// `sheetCommitToolbar`'s. `title` replaces the checkmark with a text action.
    func stepCommitToolbar<Form: SheetForm>(
        _ session: FormSession<Form>,
        title: String? = nil,
        save: @escaping (Form) async throws -> Void
    ) -> some View {
        modifier(SessionCommitToolbarModifier(session: session, title: title, showsClose: false, save: save))
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

/// `presentationDetents`, with the selection when the sheet drives its own detent.
private struct SheetDetents: ViewModifier {
    let detents: Set<PresentationDetent>
    let selection: Binding<PresentationDetent>?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let selection {
            content.presentationDetents(detents, selection: selection)
        } else {
            content.presentationDetents(detents)
        }
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
