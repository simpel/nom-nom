import SwiftUI

/// Multi-step onboarding presented on first sign-in.
/// Guides the user through:
/// 0: Identity setup (Name and optional photo)
/// 1: Pillar 01 — The Table (First dinner party setup or start solo)
/// 2: Pillar 02 — Every Meal (Notification & Email delivery preferences)
/// 3: Pillar 03 — The Living Cookbook (Recipes & finish setup)
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
                        OnboardingProfileStep(
                            firstName: $firstName,
                            lastName: $lastName,
                            photoDraft: $photoDraft
                        )
                        .transition(.opacity)
                    case 1:
                        OnboardingTableStep(partyName: $partyName)
                            .transition(.opacity)
                    case 2:
                        OnboardingMealsStep(
                            enablePush: $enablePush,
                            enableEmail: $enableEmail
                        )
                        .transition(.opacity)
                    default:
                        OnboardingCookbookStep()
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, DS.Spacing.screenHorizontal)
                .padding(.top, DS.Spacing.screenTop)
                .padding(.bottom, DS.Spacing.md)
            }
            .background(DS.Color.bg)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
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
        VStack(spacing: 8) {
            switch step {
            case 0:
                AppButton(
                    "Continue",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true,
                    disabled: firstName.trimmedName.isEmpty
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { step = 1 }
                }

            case 1:
                AppButton(
                    partyName.trimmedName.isEmpty ? "Continue Solo" : "Continue with Party",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { step = 2 }
                }

                if !partyName.trimmedName.isEmpty {
                    AppButton(
                        "Clear & Start Solo",
                        variant: .neutral,
                        style: .ghost,
                        size: .md,
                        isFullWidth: true
                    ) {
                        partyName = ""
                        withAnimation(.easeInOut(duration: 0.25)) { step = 2 }
                    }
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
                    "Get Cooking",
                    variant: .primary,
                    style: .normal,
                    size: .xl,
                    isFullWidth: true,
                    isPending: isSaving,
                    disabled: isSaving
                ) {
                    saveAndFinish()
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screenHorizontal)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.xs)
        .background(
            DS.Color.bg
                .shadow(color: DS.Color.line.opacity(0.15), radius: 6, y: -2)
        )
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
            await store.completeOnboarding()
            isSaving = false
        }
    }
}
