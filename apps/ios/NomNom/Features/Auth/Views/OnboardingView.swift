import SwiftUI

/// Multi-step onboarding presented on first sign-in.
/// Guides the user through:
/// 0: Identity setup (Name and optional photo)
/// 1: Notification & Email delivery preferences, then finish setup
struct OnboardingView: View {
    @Environment(FoodStore.self) private var store

    @State private var step = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var enablePush = true
    @State private var enableEmail = true
    @State private var isSaving = false

    private let totalSteps = 2

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.sectionCompact) {
                    switch step {
                    case 0:
                        OnboardingProfileStep(
                            firstName: $firstName,
                            lastName: $lastName,
                            photoDraft: $photoDraft
                        )
                        .transition(.opacity)
                    default:
                        OnboardingMealsStep(
                            enablePush: $enablePush,
                            enableEmail: $enableEmail
                        )
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
                ToolbarItem(placement: .principal) {
                    OnboardingStepProgress(currentStep: step, totalSteps: totalSteps)
                }
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
        .alert("Couldn't Save", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
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
                    disabled: firstName.trimmedName.isEmpty || lastName.trimmedName.isEmpty
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { step = 1 }
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
            if profile.onboardingCompletedAt == nil {
                enablePush = true
                enableEmail = true
            } else {
                enablePush = profile.notifyViaPush
                enableEmail = profile.notifyViaEmail
            }
            if let photoPath = profile.photoPath, !photoPath.isEmpty {
                photoDraft = FoodStore.PhotosDraft(existingPaths: [photoPath])
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
            guard store.errorMessage == nil else { isSaving = false; return }

            if enablePush {
                _ = await NotificationManager.shared.requestAuthorization()
            }
            // Onboarding sets the delivery channels; every event class starts on
            // and can be tuned later in Settings.
            await store.updateNotificationPreferences(
                mealInvite: true,
                mealRating: true,
                partyInvite: true,
                partyActivity: true,
                recipeLike: true,
                viaPush: enablePush,
                viaEmail: enableEmail
            )
            guard store.errorMessage == nil else { isSaving = false; return }

            await store.completeOnboarding()
            isSaving = false
        }
    }
}
