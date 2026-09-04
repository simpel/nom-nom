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
    @State private var photoData: Data? = nil
    @State private var isCreating = false

    private var canSave: Bool {
        !name.trimmedName.isEmpty && !isCreating
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    PageHeader(title: "New dinner party")

                    PartyAvatarPicker(partyName: name, photoData: $photoData, size: 80)
                        .padding(.top, -8)

                    SectionCard("Party Name") {
                        TextField("Party name (e.g. Taco Night)", text: $name)
                            .autocorrectionDisabled()
                            .onSubmit(create)
                    }

                    SectionCard("About", caption: "Optional") {
                        TextField("What is this dinner party about?", text: $about, axis: .vertical)
                            .lineLimit(3...5)
                    }

                    SectionCard("Sharing & Visibility") {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Make dinner party public", isOn: $isPublic)
                                .font(.body.weight(.medium))

                            Text("Public dinner parties can be discovered and followed by other foodies.")
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .screenTitle("New dinner party", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isCreating,
                canSave: canSave,
                onSave: create
            )
            .interactiveDismissDisabled(isCreating)
            .alert("Couldn't create dinner party",
                   isPresented: Binding(get: { store.errorMessage != nil },
                                        set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private func create() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isCreating = true
        Task {
            if let newParty = await store.createParty(
                name: partyName,
                about: about,
                isPublic: isPublic,
                photoData: photoData
            ) {
                store.currentParty = newParty
                onCreated?(newParty)
                dismiss()
            }
            isCreating = false
        }
    }
}

#Preview {
    NomNomPreview { _ in
        CreatePartySheet()
    }
}
