import SwiftUI

/// Sheet for inviting someone to a dinner party by email.
struct PartyInviteView: View {
    let party: Party

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isSending = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("friend@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit(send)
                } header: {
                    Text("Invite by email")
                } footer: {
                    Text("If they have an account, the invite appears in their inbox immediately. If they don't have an account yet, the invite is claimed when they sign up with this email.")
                }
            }
            .navigationTitle("Invite to \(party.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSending)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("Send") { send() }
                            .disabled(email.trimmedName.isEmpty)
                    }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }

    private func send() {
        let address = email.trimmedName
        guard !address.isEmpty else { return }
        isSending = true
        Task {
            let ok = await store.inviteToParty(email: address, party: party)
            isSending = false
            if ok {
                dismiss()
            }
        }
    }
}
