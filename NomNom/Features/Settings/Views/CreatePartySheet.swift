import SwiftUI

/// Dedicated sheet for creating a new dinner party.
struct CreatePartySheet: View {
    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Party name (e.g. Taco Night)", text: $name)
                        .autocorrectionDisabled()
                        .onSubmit(create)
                } header: {
                    Text("Party Name")
                } footer: {
                    Text("Any member can invite others, and meals can be shared with this party.")
                }
            }
            .screenTitle("New Dinner Party", displayMode: .inline)
            .sheetCommitToolbar(
                isSaving: isCreating,
                canSave: !name.trimmedName.isEmpty,
                onSave: create
            )
        }
        .presentationDetents([.medium])
    }

    private func create() {
        let partyName = name.trimmedName
        guard !partyName.isEmpty else { return }
        isCreating = true
        Task {
            if let newParty = await store.createParty(name: partyName) {
                store.currentParty = newParty
                dismiss()
            }
            isCreating = false
        }
    }
}
