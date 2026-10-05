import SwiftUI

/// Dedicated sheet for creating a new dinner party.
/// Designed to match the editorial look and feel of `MealEditorView` and `CreateRecipeSheet`.
struct CreatePartySheet: View {
    var onCreated: ((Party) -> Void)? = nil

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var about = ""
    @State private var isPublic = false
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var navigateToSetup = false

    private var canProceed: Bool {
        !name.trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                ScreenHeader("New dinner party")

                PartyFormFields(photoDraft: $photoDraft, name: $name, about: $about) {
                    if canProceed { navigateToSetup = true }
                }
            }
            .screenTitle("New party", displayMode: .inline)
            .sheetNextToolbar(canProceed: canProceed) {
                navigateToSetup = true
            }
            .navigationDestination(isPresented: $navigateToSetup) {
                PartySetupStepView(
                    name: name,
                    about: about,
                    photoDraft: photoDraft,
                    isPublic: $isPublic,
                    onCreated: onCreated,
                    onDismiss: { dismiss() }
                )
            }
        }
        .dsSheet()
    }
}

#Preview {
    NomNomPreview { _ in
        CreatePartySheet()
    }
}
