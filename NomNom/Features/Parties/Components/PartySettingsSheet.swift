import SwiftUI

/// Dedicated modal sheet for editing an existing dinner party's details, cover photo, and visibility.
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

    private var canSave: Bool {
        !name.trimmedName.isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    AssetPhotosPickerSection(
                        draft: $photoDraft,
                        title: "Cover Photo",
                        bucket: SupabaseConfig.partyBucket,
                        maxCount: 1
                    )

                    SectionCard("Party Name") {
                        Input("Party name (e.g. Taco Night)", text: $name)
                            .autocorrectionDisabled()
                    }

                    SectionCard("About", caption: "Optional") {
                        TextArea("What is this dinner party about?", text: $about, lineLimit: 3...5)
                    }

                    SectionCard("Sharing & Visibility") {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Make dinner party public", isOn: $isPublic)
                                .font(.body.weight(.medium))

                            Text("When enabled, other foodies can discover and follow this dinner party.")
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
            .screenTitle("Edit Party", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isSaving,
                canSave: canSave,
                onCancel: { dismiss() },
                onSave: { save() }
            )
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard !didLoad else { return }
        didLoad = true
        name = party.name
        about = party.about
        isPublic = party.isPublic
        if let photoPath = party.photoPath, !photoPath.isEmpty {
            photoDraft = FoodStore.PhotosDraft(existingPaths: [photoPath])
        }
    }

    private func save() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let photoData = photoDraft.addedData.first
            let removePhoto = photoDraft.isEmpty && party.photoPath != nil
            await store.updateParty(
                party,
                name: partyName,
                about: about,
                isPublic: isPublic,
                newPhotoData: photoData,
                removePhoto: removePhoto
            )
            isSaving = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
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


