import SwiftUI

/// Dedicated modal sheet for editing an existing dinner party's details, photos, and visibility.
struct PartySettingsSheet: View {
    let party: Party
    var onPartyLeft: (() -> Void)? = nil

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var about: String = ""
    @State private var isPublic: Bool = false
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var isSaving = false
    @State private var didLoad = false
    @State private var saveError: String?

    private var canSave: Bool {
        !name.trimmedName.isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                PartyFormFields(photoDraft: $photoDraft, name: $name, about: $about)

                VisibilityToggleCard.party(isPublic: $isPublic)
            }
            .screenTitle("Edit Party", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                canSave: canSave,
                onCancel: { dismiss() },
                onSave: { save() }
            )
            .onAppear(perform: populate)
            .alert("Couldn't Save", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .dsSheet()
    }

    private func populate() {
        guard !didLoad else { return }
        didLoad = true
        name = party.name
        about = party.about
        isPublic = party.isPublic
        photoDraft = FoodStore.PhotosDraft(existingPaths: party.photoPaths)
    }

    private func save() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            await store.updateParty(
                party,
                name: partyName,
                about: about,
                isPublic: isPublic,
                photos: photoDraft
            )
            isSaving = false
            if store.errorMessage == nil {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            } else {
                saveError = store.errorMessage
                store.errorMessage = nil
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartySettingsSheet(party: party)
        }
    }
}


