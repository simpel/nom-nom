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
                VStack(spacing: DS.Spacing.s6) {
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
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s4)
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
                    // A sheet toolbar uses a system button (AppButton README "Rules").
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back", systemImage: "chevron.backward") {
                            withAnimation(DS.Motion.layout) { step -= 1 }
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
        Group {
            switch step {
            case 0:
                AppButton("Continue", size: .lg, fullWidth: true) {
                    withAnimation(DS.Motion.layout) { step = 1 }
                }
                .disabled(firstName.trimmedName.isEmpty || lastName.trimmedName.isEmpty)

            default:
                AppButton("Get cooking", size: .lg, fullWidth: true, isLoading: isSaving) {
                    saveAndFinish()
                }
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.s3)
        .padding(.bottom, DS.Spacing.s2)
        // README "Layout": no shadows except on things that float; the bar sits on `bg`.
        .background(DS.Color.bg)
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
