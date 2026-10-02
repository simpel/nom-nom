import SwiftUI

/// Multi-step onboarding presented on first sign-in:
/// 1. Identity (name and optional photo)
/// 2. Dinner party: start one or join one with an invite code. Skipped when the
///    viewer arrived with an invite (an invite link, or an email invite), which
///    then waits in the inbox to be accepted or declined.
/// 3. Notification & email delivery preferences, then finish setup
struct OnboardingView: View {
    private enum Step { case profile, party, notifications }

    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications

    @State private var stepIndex = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var photoDraft = FoodStore.PhotosDraft()
    @State private var partyChoice = OnboardingPartyChoice.create
    @State private var partyName = ""
    @State private var inviteCode = ""
    @State private var codeError: String?
    @State private var joinedByCode = false
    @State private var arrivedWithInvite = false
    @State private var enablePush = true
    @State private var enableEmail = true
    @State private var isSaving = false

    private var steps: [Step] {
        arrivedWithInvite ? [.profile, .notifications] : [.profile, .party, .notifications]
    }
    private var step: Step { steps[min(stepIndex, steps.count - 1)] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.s6) {
                    switch step {
                    case .profile:
                        OnboardingProfileStep(firstName: $firstName, lastName: $lastName, photoDraft: $photoDraft)
                            .transition(.opacity)
                    case .party:
                        OnboardingPartyStep(choice: $partyChoice, partyName: $partyName,
                                            inviteCode: $inviteCode, codeError: codeError)
                            .transition(.opacity)
                    case .notifications:
                        OnboardingMealsStep(enablePush: $enablePush, enableEmail: $enableEmail)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s4)
            }
            .background(DS.Color.bg)
            .safeAreaInset(edge: .bottom) {
                Group {
                    switch step {
                    case .profile:
                        AppButton("Continue", size: .lg, fullWidth: true) { advance() }
                            .disabled(firstName.trimmedName.isEmpty || lastName.trimmedName.isEmpty)
                    case .party:
                        AppButton("Continue", size: .lg, fullWidth: true, isLoading: isSaving) { continueFromParty() }
                            .disabled(partyChoice == .create ? partyName.trimmedName.isEmpty : inviteCode.trimmedName.isEmpty)
                    case .notifications:
                        AppButton("Get cooking", size: .lg, fullWidth: true, isLoading: isSaving) { saveAndFinish() }
                    }
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s2)
                // README "Layout": no shadows except on things that float; the bar sits on `bg`.
                .background(DS.Color.bg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    OnboardingStepProgress(currentStep: stepIndex, totalSteps: steps.count)
                }
                if stepIndex > 0 {
                    // A sheet toolbar uses a system button (AppButton README "Rules").
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back", systemImage: "chevron.backward") {
                            withAnimation(DS.Motion.layout) { stepIndex -= 1 }
                        }
                        .disabled(isSaving)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            loadInitialState()
            claimInviteLink()
        }
        .onChange(of: notifications.pendingURL) { _, _ in claimInviteLink() }
        .onChange(of: inviteCode) { _, _ in codeError = nil }
        .alert("Couldn't Save", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: - Actions

    private func advance() {
        withAnimation(DS.Motion.layout) { stepIndex += 1 }
    }

    private func loadInitialState() {
        guard let profile = store.myProfile else { return }
        firstName = profile.firstName
        lastName = profile.lastName
        if profile.onboardingCompletedAt != nil {
            enablePush = profile.notifyViaPush
            enableEmail = profile.notifyViaEmail
        }
        if let photoPath = profile.photoPath, !photoPath.isEmpty {
            photoDraft = FoodStore.PhotosDraft(existingPaths: [photoPath])
        }
        // An email invite (claimed at sign-up) or an existing party skips the party step.
        if !store.pendingPartyInvites.isEmpty || !store.myParties.isEmpty {
            arrivedWithInvite = true
        }
    }

    /// The app was opened from a party's invite link: file the invite now, so it waits
    /// in the inbox, and skip the party step. Only while the party step is still ahead.
    private func claimInviteLink() {
        guard stepIndex == 0, let url = notifications.pendingURL,
              case .partyInvite(let partyID) = DeepLink(url: url) else { return }
        notifications.pendingURL = nil
        arrivedWithInvite = true
        Task { await store.requestPartyInvite(partyID: partyID) }
    }

    /// Creating waits for the last step; a code is checked now, so a typo shows here.
    private func continueFromParty() {
        guard partyChoice == .join else { return advance() }
        isSaving = true
        Task {
            do {
                _ = try await store.requestPartyInvite(code: inviteCode)
                joinedByCode = true
                isSaving = false
                advance()
            } catch {
                codeError = error.localizedDescription
                isSaving = false
            }
        }
    }

    private func saveAndFinish() {
        isSaving = true
        let photoData = photoDraft.addedData.first
        Task {
            defer { isSaving = false }
            await store.updateProfile(firstName: firstName, lastName: lastName, newPhotoData: photoData)
            guard store.errorMessage == nil else { return }

            if enablePush {
                _ = await NotificationManager.shared.requestAuthorization()
            }
            // Onboarding sets the delivery channels; every event class starts on
            // and can be tuned later in Settings.
            await store.updateNotificationPreferences(
                mealInvite: true, mealRating: true, partyInvite: true, partyActivity: true,
                recipeLike: true, viaPush: enablePush, viaEmail: enableEmail
            )
            guard store.errorMessage == nil else { return }

            let joining = arrivedWithInvite || joinedByCode
            if !joining, store.myParties.isEmpty {
                guard await store.createParty(name: partyName) != nil else { return }
            }
            notifications.pendingInbox = joining && !store.pendingPartyInvites.isEmpty
            await store.completeOnboarding()
        }
    }
}
