import SwiftUI

/// Multi-step onboarding presented on first sign-in.
/// Guides the user through:
/// 0: Concept explanation (Dinner Parties, Recipes, Meals)
/// 1: Profile setup (Name and optional photo)
/// 2: Notification & Email permissions (with clear explanations)
/// 3: First dinner party setup (or start solo)
struct OnboardingView: View {
    @Environment(FoodStore.self) private var store

    @State private var step = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var enablePush = true
    @State private var enableEmail = true
    @State private var partyName = ""
    @State private var isSaving = false

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.sectionCompact) {
                    OnboardingStepProgress(currentStep: step, totalSteps: totalSteps)

                    switch step {
                    case 0:
                        OnboardingConceptsStep()
                            .transition(.opacity)
                    case 1:
                        OnboardingProfileStep(
                            firstName: $firstName,
                            lastName: $lastName,
                            photoDraft: $photoDraft
                        )
                        .transition(.opacity)
                    case 2:
                        OnboardingNotificationsStep(
                            enablePush: $enablePush,
                            enableEmail: $enableEmail
                        )
                        .transition(.opacity)
                    default:
                        OnboardingPartyStep(partyName: $partyName)
                            .transition(.opacity)
                    }

                    bottomBar
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .background(DS.Color.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                step -= 1
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.backward")
                                Text("Back")
                            }
                            .font(.subheadline)
                        }
                        .disabled(isSaving)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear(perform: loadInitialState)
    }

    // MARK: - Bottom Actions

    private var bottomBar: some View {
        VStack(spacing: 12) {
            switch step {
            case 0:
                AppButton("Get Started", variant: .primary, style: .normal, size: .xl, isFullWidth: true) {
                    withAnimation(.easeInOut(duration: 0.25)) { step = 1 }
                }

            case 1:
                AppButton(
                    "Continue",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true,
                    disabled: firstName.trimmedName.isEmpty
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { step = 2 }
                }

            case 2:
                AppButton(
                    "Continue",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true,
                    isPending: isSaving,
                    disabled: isSaving
                ) {
                    confirmNotificationsAndProceed()
                }

            default:
                AppButton(
                    partyName.trimmedName.isEmpty ? "Start Solo & Finish" : "Create Party & Finish",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true,
                    isPending: isSaving,
                    disabled: isSaving
                ) {
                    saveAndFinish()
                }

                if !partyName.trimmedName.isEmpty {
                    AppButton(
                        "Skip party creation",
                        variant: .neutral,
                        style: .ghost,
                        size: .md,
                        isFullWidth: true,
                        disabled: isSaving
                    ) {
                        partyName = ""
                        saveAndFinish()
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func loadInitialState() {
        if let profile = store.myProfile {
            firstName = profile.firstName
            lastName = profile.lastName
            enablePush = profile.notifyPushPartyInvite || profile.notifyPushMealInvite
            enableEmail = profile.notifyEmailPartyInvite || profile.notifyEmailMealInvite
            if let photoPath = profile.photoPath, !photoPath.isEmpty {
                photoDraft = FoodStore.PhotosDraft(existingPaths: [photoPath])
            }
        }
    }

    private func confirmNotificationsAndProceed() {
        isSaving = true
        Task {
            if enablePush {
                _ = await NotificationManager.shared.requestAuthorization()
            }
            await store.updateNotificationPreferences(
                pushParty: enablePush,
                emailParty: enableEmail,
                pushMeal: enablePush,
                emailMeal: enableEmail
            )
            isSaving = false
            withAnimation(.easeInOut(duration: 0.25)) {
                step = 3
            }
        }
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
