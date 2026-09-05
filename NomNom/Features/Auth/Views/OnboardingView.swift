import SwiftUI

/// Onboarding screen presented on first sign-in to collect first name, last name, optional profile photo,
/// and optionally set up a first dinner party.
struct OnboardingView: View {
    @Environment(FoodStore.self) private var store

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var partyName = ""
    @State private var isSaving = false
    @State private var step = 0 // 0: Name/Profile, 1: First Party

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.section) {
                    if step == 0 {
                        profileStep
                    } else {
                        partyStep
                    }

                    bottomBar
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .onAppear {
            if let profile = store.myProfile {
                firstName = profile.firstName
                lastName = profile.lastName
                if let photoPath = profile.photoPath, !photoPath.isEmpty {
                    photoDraft = FoodStore.PhotosDraft(existingPaths: [photoPath])
                }
            }
        }
    }

    // MARK: - Step 1: Profile

    private var profileStep: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(title: "Welcome to Nom Nom")

            AssetPhotosPickerSection(
                draft: $photoDraft,
                title: "Profile Photo",
                bucket: SupabaseConfig.profileBucket,
                maxCount: 1
            )

            SectionCard("Your Name") {
                VStack(spacing: 8) {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)

                    Divider()

                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                }
            }
        }
    }

    // MARK: - Step 2: Dinner Party

    private var partyStep: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(title: "Dinner Party")

            SectionCard("Party Name", caption: "Optional") {
                TextField("Party name (e.g. Taco Night)", text: $partyName)
                    .textInputAutocapitalization(.words)
            }
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
                    Text(partyName.trimmedName.isEmpty ? "Start with Just Me" : "Create Party & Finish")
                        .frame(maxWidth: .infinity)
                        .pendingState(isSaving)
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
                    .foregroundStyle(DS.Color.textSecondary)
                    .disabled(isSaving)
                }
            }
        }
        .padding(.top, 8)
    }

    private func saveAndFinish() {
        isSaving = true
        let photoData = photoDraft.addedData.first
        Task {
            await store.updateProfile(
                firstName: firstName,
                lastName: lastName,
                newPhotoData: photoData
            )
            if !partyName.trimmedName.isEmpty {
                await store.createParty(name: partyName)
            }
            isSaving = false
        }
    }
}
