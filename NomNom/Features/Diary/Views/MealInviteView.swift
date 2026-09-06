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
            VStack(spacing: DS.Spacing.section) {
                SectionCard("Invite by email") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Input(
                                "their@email.com",
                                text: $email,
                                size: .sm,
                                isFocused: $focused
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.send)
                            .onSubmit(send)

                            AppButton(
                                "Invite",
                                variant: .primary,
                                style: .normal,
                                size: .sm,
                                isPending: isSending,
                                disabled: isSending || email.trimmingCharacters(in: .whitespaces).isEmpty,
                                action: send
                            )
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
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
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
