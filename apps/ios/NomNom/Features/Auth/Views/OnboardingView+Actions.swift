import SwiftUI

// OnboardingView's actions: loading, invites, and finishing into Meals.
extension OnboardingView {
    func advance() {
        withAnimation(DS.Motion.layout) { stepIndex += 1 }
    }

    func loadInitialState() {
        hadPartyAtStart = !store.myParties.isEmpty
        if !store.pendingPartyInvites.isEmpty { partyChoice = .invites }
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
    }

    /// The app was opened from a party's invite link: file the invite now, so it waits
    /// in the party step's list. Only while the party step is still ahead.
    func claimInviteLink() {
        guard step != .party, step != .pickParty, let url = notifications.pendingURL,
              case .partyInvite(let partyID) = DeepLink(url: url) else { return }
        notifications.pendingURL = nil
        partyChoice = .invites
        Task { await store.requestPartyInvite(partyID: partyID) }
    }

    func accept(_ invite: PartyInvite) {
        busyInviteID = invite.id
        Task {
            await store.acceptPartyInvite(invite)
            busyInviteID = nil
            guard store.errorMessage == nil, !joinedPartyIDs.contains(invite.partyID) else { return }
            withAnimation(DS.Motion.layout) { joinedPartyIDs.append(invite.partyID) }
        }
    }

    func decline(_ invite: PartyInvite) {
        busyInviteID = invite.id
        Task {
            await store.declinePartyInvite(invite)
            busyInviteID = nil
        }
    }

    /// A code becomes a pending invite in the list; a party she's already in counts as joined.
    func addInviteCode() {
        guard !inviteCode.trimmedName.isEmpty, !isAddingCode else { return }
        isAddingCode = true
        Task {
            defer { isAddingCode = false }
            do {
                let partyID = try await store.requestPartyInvite(code: inviteCode)
                inviteCode = ""
                if store.isMember(of: partyID), !joinedPartyIDs.contains(partyID) {
                    joinedPartyIDs.append(partyID)
                }
            } catch {
                codeError = error.localizedDescription
            }
        }
    }

    /// Saves the profile and delivery channels, starts the party (or selects `landing`),
    /// then completes onboarding; RootTabView opens on Meals for the current party.
    func finish(landing: UUID?) {
        isSaving = true
        let photoData = photoDraft.addedData.first
        let removePhoto = photoDraft.isEmpty && store.myProfile?.photoPath != nil
        Task {
            defer {
                isSaving = false
                pickingID = nil
            }
            await store.updateProfile(firstName: firstName, lastName: lastName,
                                      newPhotoData: photoData, removePhoto: removePhoto)
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

            if let landing, let party = store.party(landing) {
                store.currentParty = party
            } else if !hadPartyAtStart, partyChoice == .create {
                guard await store.createParty(name: partyName) != nil else { return }
            }
            await store.completeOnboarding()
        }
    }
}
