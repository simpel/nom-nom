import SwiftUI
import UserNotifications

/// Form section for configuring push notification and email delivery preferences.
struct NotificationPreferencesSection: View {
    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications

    @State private var pushParty = true
    @State private var emailParty = true
    @State private var pushMeal = true
    @State private var emailMeal = true
    @State private var hasLoaded = false

    var body: some View {
        SectionCard("Notification Preferences") {
            VStack(spacing: 12) {
                if notifications.authorizationStatus == .denied && (pushParty || pushMeal) {
                    systemDisabledWarning
                    Divider()
                }

                dinnerPartyToggles
                Divider()
                mealInviteToggles

                Text("Choose what is sent to your device via notifications and what is sent to your inbox via email.")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.top, 4)
            }
        }
        .onAppear(perform: loadPreferences)
        .onChange(of: store.myProfile) { _, _ in
            loadPreferences()
        }
    }

    // MARK: - Subviews

    private var dinnerPartyToggles: some View {
        Group {
            Toggle(isOn: Binding(
                get: { pushParty },
                set: { newValue in
                    pushParty = newValue
                    handlePushToggle(newValue)
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dinner Party Invites")
                        Text("When added to a dinner party")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                } icon: {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.tint)
                }
            }

            Toggle(isOn: Binding(
                get: { emailParty },
                set: { newValue in
                    emailParty = newValue
                    persist()
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dinner Party Invite Emails")
                        Text("Receive email for dinner party invitations")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                } icon: {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private var mealInviteToggles: some View {
        Group {
            Toggle(isOn: Binding(
                get: { pushMeal },
                set: { newValue in
                    pushMeal = newValue
                    handlePushToggle(newValue)
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meal Invitations")
                        Text("When added to rate a meal")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                } icon: {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.tint)
                }
            }

            Toggle(isOn: Binding(
                get: { emailMeal },
                set: { newValue in
                    emailMeal = newValue
                    persist()
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meal Invite Emails")
                        Text("Receive email when invited to rate a dish")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                } icon: {
                    Image(systemName: "envelope.badge.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private var systemDisabledWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.orange)
                Text("Notifications Disabled")
                    .font(.subheadline.bold())
            }
            Text("Push notifications are turned off in iOS Settings. Tap to enable them.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)
            Button("Open iOS Settings") {
                notifications.openSystemSettings()
            }
            .font(.caption.bold())
            .buttonStyle(.borderless)
            .tint(.orange)
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func loadPreferences() {
        guard let profile = store.myProfile else { return }
        pushParty = profile.notifyPushPartyInvite
        emailParty = profile.notifyEmailPartyInvite
        pushMeal = profile.notifyPushMealInvite
        emailMeal = profile.notifyEmailMealInvite
        hasLoaded = true
    }

    private func handlePushToggle(_ isEnabled: Bool) {
        persist()
        if isEnabled {
            Task {
                if notifications.authorizationStatus == .notDetermined {
                    let granted = await notifications.requestAuthorization()
                    if granted, let token = notifications.deviceToken {
                        await store.registerDeviceToken(token)
                    }
                }
            }
        }
    }

    private func persist() {
        guard hasLoaded else { return }
        Task {
            await store.updateNotificationPreferences(
                pushParty: pushParty,
                emailParty: emailParty,
                pushMeal: pushMeal,
                emailMeal: emailMeal
            )
        }
    }
}
