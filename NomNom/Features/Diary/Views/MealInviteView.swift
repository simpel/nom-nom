import SwiftUI

/// Ask other people to rate a meal you cooked.
struct MealInviteView: View {
    let mealID: UUID

    @Environment(FoodStore.self) private var store

    @State private var email = ""
    @State private var isSending = false
    @FocusState private var focused: Bool

    private var invites: [MealInvite] {
        store.invites(forMeal: mealID).sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionCard("Invite by email") {
                    VStack(alignment: .leading, spacing: 10) {
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
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }

                        Text("If they already have an account this lands on their Meals page straight away. If not, the invitation waits and they get it the first time they sign in with that address.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !invites.isEmpty {
                    SectionCard("Invited") {
                        VStack(spacing: 8) {
                            ForEach(invites) { invite in
                                MealInviteRow(invite: invite)
                                if invite.id != invites.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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

typealias InviteView = MealInviteView

#Preview {
    NomNomPreview { store in
        if let meal = store.meals.first {
            MealInviteView(mealID: meal.id)
        }
    }
}
