import SwiftUI

/// Dedicated sheet for creating a new dinner party.
/// Designed to match the editorial look and feel of `MealEditorView` and `CreateRecipeSheet`.
struct CreatePartySheet: View {
    var onCreated: ((Party) -> Void)? = nil

    @State private var session = FormSession(PartyForm(), kind: .create)
    @State private var navigateToSetup = false

    private var canProceed: Bool { session.form.isValid }

    var body: some View {
        NavigationStack {
            SheetBody {
                ScreenHeader("New dinner party")

                PartyFormFields(
                    photoDraft: $session.form.photos,
                    name: $session.form.name,
                    about: $session.form.about
                ) {
                    if canProceed { navigateToSetup = true }
                }
            }
            .screenTitle("New party", displayMode: .inline)
            .sheetNextToolbar(session, canProceed: canProceed) {
                navigateToSetup = true
            }
            .navigationDestination(isPresented: $navigateToSetup) {
                PartySetupStepView(session: session, onCreated: onCreated)
            }
        }
        .editorSheet(session, errorTitle: "Couldn\u{2019}t save dinner party")
    }
}

#Preview {
    NomNomPreview { _ in
        CreatePartySheet()
    }
}
