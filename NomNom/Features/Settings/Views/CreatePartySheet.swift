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
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    PageHeader(title: "New dinner party")

                    AssetPhotosPickerSection(
                        draft: $photoDraft,
                        title: "Cover Photo",
                        bucket: SupabaseConfig.partyBucket,
                        maxCount: 1
                    )

                    SectionCard("Party Name") {
                        Input("Party name (e.g. Taco Night)", text: $name)
                            .autocorrectionDisabled()
                            .onSubmit {
                                if canProceed { navigateToSetup = true }
                            }
                    }

                    SectionCard("About", caption: "Optional") {
                        TextArea("What is this dinner party about?", text: $about, lineLimit: 3...5)
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("New Party", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") {
                        navigateToSetup = true
                    }
                    .disabled(!canProceed)
                    .fontWeight(.semibold)
                }
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
    }
}

#Preview {
    NomNomPreview { _ in
        CreatePartySheet()
    }
}
