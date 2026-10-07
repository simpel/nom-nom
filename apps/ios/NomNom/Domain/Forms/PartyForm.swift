import Foundation

/// A dinner party while it is created or edited. Edited by CreatePartySheet (then
/// PartySetupStepView) and PartySettingsSheet.
struct PartyForm: SheetForm {
    var name: String = ""
    var about: String = ""
    var isPublic: Bool = false
    var photos = FoodStore.PhotosDraft()

    var isValid: Bool { !name.trimmedName.isEmpty }
}

extension PartyForm {
    /// An existing party as it is saved.
    init(_ party: Party) {
        name = party.name
        about = party.about
        isPublic = party.isPublic
        photos = FoodStore.PhotosDraft(existingPaths: party.photoPaths)
    }
}
