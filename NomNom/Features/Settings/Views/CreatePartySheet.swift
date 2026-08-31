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
            .navigationTitle("New Dinner Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isCreating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Button("Create") { create() }
                            .disabled(name.trimmedName.isEmpty)
                    }
                }
            }
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
