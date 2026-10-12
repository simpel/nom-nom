import SwiftUI

/// Dedicated modal sheet for editing an existing dinner party's details, photos, and visibility.
struct PartySettingsSheet: View {
    let party: Party
    var onPartyLeft: (() -> Void)? = nil

    @Environment(FoodStore.self) private var store

    @State private var session: FormSession<PartyForm>

    init(party: Party, onPartyLeft: (() -> Void)? = nil) {
        self.party = party
        self.onPartyLeft = onPartyLeft
        self._session = State(initialValue: FormSession(PartyForm(party)))
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                PartyFormFields(
                    photoDraft: $session.form.photos,
                    name: $session.form.name,
                    about: $session.form.about
                )

                VisibilityToggleCard.party(isPublic: $session.form.isPublic)
            }
            .screenTitle("Edit Party", displayMode: .inline)
            .sheetCommitToolbar(session) { form in
                await store.updateParty(
                    party,
                    name: form.name.trimmedName,
                    about: form.about,
                    isPublic: form.isPublic,
                    photos: form.photos
                )
                try store.throwIfFailed()
            }
        }
        .editorSheet(session)
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartySettingsSheet(party: party)
        }
    }
}
