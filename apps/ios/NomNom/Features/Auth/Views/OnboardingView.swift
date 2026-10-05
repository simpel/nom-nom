import SwiftUI

/// Multi-step onboarding presented on first sign-in:
/// 1. Identity (name and optional photo)
/// 2. Notification & email delivery preferences
/// 3. Dinner party: start one, or accept the pending invites (several are fine; a code
///    or invite link adds one). Skipped when the account is already in a party.
/// 4. Only after joining more than one party: pick which one to open.
/// It ends on Meals for the party she started, joined or picked.
struct OnboardingView: View {
    enum Step { case profile, notifications, party, pickParty }

    @Environment(FoodStore.self) var store
    @Environment(NotificationManager.self) var notifications

    @State var stepIndex = 0
    @State var firstName = ""
    @State var lastName = ""
    @State var photoDraft = FoodStore.PhotosDraft()
    @State var enablePush = true
    @State var enableEmail = true
    @State var partyChoice = OnboardingPartyChoice.create
    @State var partyName = ""
    @State var inviteCode = ""
    @State var codeError: String?
    @State var isAddingCode = false
    @State var joinedPartyIDs: [UUID] = []
    @State var busyInviteID: UUID?
    @State var pickingID: UUID?
    @State var hadPartyAtStart = false
    @State var isSaving = false

    var steps: [Step] {
        if hadPartyAtStart { return [.profile, .notifications] }
        let picks = partyChoice == .invites && joinedPartyIDs.count > 1
        return picks ? [.profile, .notifications, .party, .pickParty] : [.profile, .notifications, .party]
    }
    var step: Step { steps[min(stepIndex, steps.count - 1)] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.s6) {
                    stepContent.transition(.opacity)
                }
                .padding(.horizontal, DS.Spacing.gutter)
                .padding(.top, DS.Spacing.s5)
                .padding(.bottom, DS.Spacing.s4)
            }
            .background(DS.Color.bg)
            .safeAreaInset(edge: .bottom) {
                if step != .pickParty {
                    bottomButton
                        .padding(.horizontal, DS.Spacing.gutter)
                        .padding(.top, DS.Spacing.s3)
                        .padding(.bottom, DS.Spacing.s2)
                        // README "Layout": no shadows except on things that float; the bar sits on `bg`.
                        .background(DS.Color.bg)
                }
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
                        .barItemStyle()
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

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .profile:
            OnboardingProfileStep(firstName: $firstName, lastName: $lastName, photoDraft: $photoDraft)
        case .notifications:
            OnboardingMealsStep(enablePush: $enablePush, enableEmail: $enableEmail)
        case .party:
            OnboardingPartyStep(
                choice: $partyChoice, partyName: $partyName, inviteCode: $inviteCode,
                codeError: codeError, isAddingCode: isAddingCode,
                joinedPartyIDs: joinedPartyIDs, busyInviteID: busyInviteID,
                onAddCode: addInviteCode, onAccept: accept, onDecline: decline
            )
        case .pickParty:
            OnboardingPickPartyStep(
                parties: joinedPartyIDs.compactMap { store.party($0) },
                pickingID: pickingID
            ) { party in
                pickingID = party.id
                finish(landing: party.id)
            }
        }
    }

    @ViewBuilder
    private var bottomButton: some View {
        switch step {
        case .profile:
            AppButton("Continue", size: .lg, fullWidth: true) { advance() }
                .disabled(firstName.trimmedName.isEmpty || lastName.trimmedName.isEmpty)
        case .notifications:
            if steps.last == .notifications {
                AppButton("Get cooking", size: .lg, fullWidth: true, isLoading: isSaving) { finish(landing: nil) }
            } else {
                AppButton("Continue", size: .lg, fullWidth: true) { advance() }
            }
        case .party:
            partyButton
        case .pickParty:
            EmptyView()
        }
    }

    @ViewBuilder
    private var partyButton: some View {
        switch partyChoice {
        case .create:
            AppButton("Get cooking", size: .lg, fullWidth: true, isLoading: isSaving) { finish(landing: nil) }
                .disabled(partyName.trimmedName.isEmpty)
        case .invites:
            let many = joinedPartyIDs.count > 1
            AppButton(many ? "Continue" : "Get cooking", size: .lg, fullWidth: true, isLoading: isSaving) {
                if many { advance() } else { finish(landing: joinedPartyIDs.first) }
            }
            .disabled(joinedPartyIDs.isEmpty || busyInviteID != nil)
        }
    }
}
