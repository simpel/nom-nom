import SwiftUI
import UserNotifications

/// Form section for configuring delivery preferences (Notification, Email, Both, Off) per event.
struct NotificationPreferencesSection: View {
    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications

    enum DeliveryPreference: String, CaseIterable, Identifiable {
        case both = "Both"
        case push = "Notification"
        case email = "Email"
        case none = "Off"

        var id: String { rawValue }

        init(push: Bool, email: Bool) {
            switch (push, email) {
            case (true, true): self = .both
            case (true, false): self = .push
            case (false, true): self = .email
            case (false, false): self = .none
            }
        }

        var isPush: Bool { self == .both || self == .push }
        var isEmail: Bool { self == .both || self == .email }
    }

    @State private var partyPreference: DeliveryPreference = .both
    @State private var mealPreference: DeliveryPreference = .both
    @State private var hasLoaded = false

    var body: some View {
        SectionCard("Notifications") {
            VStack(alignment: .leading, spacing: 14) {
                if notifications.authorizationStatus == .denied && (partyPreference.isPush || mealPreference.isPush) {
                    systemDisabledWarning
                    Divider()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dinner Party Invites")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DS.Color.textPrimary)

                    Picker("Dinner Party Invites", selection: Binding(
                        get: { partyPreference },
                        set: { newPref in
                            partyPreference = newPref
                            handlePreferenceChange(pushEnabled: newPref.isPush)
                        }
                    )) {
                        ForEach(DeliveryPreference.allCases) { pref in
                            Text(pref.rawValue).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)
                }



                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Invitations")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DS.Color.textPrimary)

                    Picker("Meal Invitations", selection: Binding(
                        get: { mealPreference },
                        set: { newPref in
                            mealPreference = newPref
                            handlePreferenceChange(pushEnabled: newPref.isPush)
                        }
                    )) {
                        ForEach(DeliveryPreference.allCases) { pref in
                            Text(pref.rawValue).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .onAppear(perform: loadPreferences)
        .onChange(of: store.myProfile) { _, _ in
            loadPreferences()
        }
    }

    // MARK: - Subviews

    private var systemDisabledWarning: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bell.slash")
                    .foregroundStyle(.orange)
                Text("Notifications Disabled in iOS Settings")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
            }

            AppButton(
                "Open iOS Settings",
                variant: .neutral,
                style: .outlined,
                size: .sm
            ) {
                notifications.openSystemSettings()
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Actions

    private func loadPreferences() {
        guard let profile = store.myProfile else { return }
        partyPreference = DeliveryPreference(push: profile.notifyPushPartyInvite, email: profile.notifyEmailPartyInvite)
        mealPreference = DeliveryPreference(push: profile.notifyPushMealInvite, email: profile.notifyEmailMealInvite)
        hasLoaded = true
    }

    private func handlePreferenceChange(pushEnabled: Bool) {
        persist()
        if pushEnabled {
            Task {
                if notifications.authorizationStatus == .notDetermined {
                    _ = await notifications.requestAuthorization()
                } else if notifications.authorizationStatus == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    private func persist() {
        guard hasLoaded else { return }
        Task {
            await store.updateNotificationPreferences(
                pushParty: partyPreference.isPush,
                emailParty: partyPreference.isEmail,
                pushMeal: mealPreference.isPush,
                emailMeal: mealPreference.isEmail
            )
        }
    }
}
