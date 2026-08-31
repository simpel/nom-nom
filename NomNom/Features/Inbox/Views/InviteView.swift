import SwiftUI

/// Ask other people to rate a meal you cooked.
struct InviteView: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store

    @State private var email = ""
    @State private var isSending = false
    @FocusState private var focused: Bool

    private var invites: [MealInvite] {
        store.invites(forMeal: mealID).sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    TextField("their@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit(send)

                    if isSending {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Invite", action: send)
                            .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            } header: {
                Text("Invite by email")
            } footer: {
                Text("If they already have an account this lands in their inbox straight away. If not, the invitation waits and they get it the first time they sign in with that address.")
            }

            if !invites.isEmpty {
                Section("Invited") {
                    ForEach(invites) { invite in
                        InviteRow(invite: invite)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await store.revoke(invite: invite) }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Ask for ratings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = invites.isEmpty }
    }

    private func send() {
        let address = email
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSending = true
        Task {
            let ok = await store.invite(email: address, toMeal: mealID)
            isSending = false
            if ok {
                email = ""
                focused = false
            }
        }
    }
}
