import SwiftUI

/// Onboarding screen presented on first sign-in to collect first name, last name, avatar emoji,
/// and optionally set up a first dinner party.
struct OnboardingView: View {
    @Environment(FoodStore.self) private var store

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var emoji = "🧑"
    @State private var partyName = ""
    @State private var isSaving = false
    @State private var step = 0 // 0: Name/Profile, 1: First Party

    private let emojiChoices = ["🧑", "👩", "👨", "🧒", "🦊", "🐻", "🐼", "🦁", "🐧", "🦄", "🥑", "🍕", "🌮", "🍣"]

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.section) {
                Spacer()

                if step == 0 {
                    profileStep
                } else {
                    partyStep
                }

                Spacer()

                bottomBar
            }
            .padding(24)
            .background(DS.Color.bg)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .onAppear {
            if let profile = store.myProfile {
                firstName = profile.firstName
                lastName = profile.lastName
                emoji = profile.avatarEmoji
            }
        }
    }

    // MARK: - Step 1: Profile

    private var profileStep: some View {
        VStack(spacing: DS.Spacing.section) {
            // Selected avatar display
            Text(emoji)
                .font(.system(size: 56))
                .frame(width: 88, height: 88)
                .background(DS.Color.panel)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            // Emoji picker grid / horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(emojiChoices, id: \.self) { choice in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                emoji = choice
                            }
                        } label: {
                            Text(choice)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(emoji == choice ? DS.Color.accentSoft : DS.Color.panel)
                                .clipShape(Circle())
                                .overlay {
                                    if emoji == choice {
                                        Circle().stroke(DS.Color.accent, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }

            VStack(spacing: 8) {
                Text("Welcome to Nom Nom!")
                    .font(AppTypography.displayL)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("What should other dinner party members call you?")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                TextField("First name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)

                TextField("Last name", text: $lastName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.familyName)
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Step 2: Dinner Party

    private var partyStep: some View {
        VStack(spacing: DS.Spacing.section) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Dinner Parties")
                    .font(AppTypography.displayL)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("A dinner party is a group of people you eat and share food ratings with (e.g. your household, roomies, or friends).")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Party name (e.g. The Sandens, Friday Tacos)", text: $partyName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Bottom Actions

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if step == 0 {
                Button {
                    withAnimation { step = 1 }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(firstName.trimmedName.isEmpty)
            } else {
                Button {
                    saveAndFinish()
                } label: {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text(partyName.trimmedName.isEmpty ? "Start with Just Me" : "Create Party & Finish")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSaving)

                if !partyName.trimmedName.isEmpty {
                    Button("Skip party creation") {
                        partyName = ""
                        saveAndFinish()
                    }
                    .font(.footnote)
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveAndFinish() {
        isSaving = true
        Task {
            await store.updateProfile(firstName: firstName, lastName: lastName, emoji: emoji)
            if !partyName.trimmedName.isEmpty {
                await store.createParty(name: partyName)
            }
            isSaving = false
        }
    }
}
