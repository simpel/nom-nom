import SwiftUI
import UserNotifications

/// One on/off switch per event, plus two global delivery-channel switches.
/// The in-app inbox always fills regardless — these only gate push and email.
struct NotificationPreferencesSection: View {
    @Environment(FoodStore.self) private var store
    @Environment(NotificationManager.self) private var notifications

    // Per-event switches.
    @State private var mealInvite = true
    @State private var mealRating = true
    @State private var partyInvite = true
    @State private var partyActivity = true
    @State private var recipeLike = true
    // Delivery channels.
    @State private var viaPush = true
    @State private var viaEmail = false

    @State private var hasLoaded = false

    private var anyEventOn: Bool {
        mealInvite || mealRating || partyInvite || partyActivity || recipeLike
    }

    private var showsPermissionWarning: Bool {
        notifications.authorizationStatus == .denied && viaPush && anyEventOn
    }

    var body: some View {
        SectionCard("Notifications") {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                if showsPermissionWarning {
                    permissionWarning
                    Divider()
                }

                VStack(spacing: DS.Spacing.sm) {
                    eventRow(
                        "Meal invitations",
                        detail: "Someone asks you to rate a meal",
                        isOn: $mealInvite
                    )
                    eventRow(
                        "Ratings on your meals",
                        detail: "Someone rates a dish you cooked",
                        isOn: $mealRating
                    )
                    eventRow(
                        "Dinner party invitations",
                        detail: "Someone invites you to a party",
                        isOn: $partyInvite
                    )
                    eventRow(
                        "Party activity",
                        detail: "Someone joins or follows your party",
                        isOn: $partyActivity
                    )
                    eventRow(
                        "Recipe likes",
                        detail: "Someone likes one of your recipes",
                        isOn: $recipeLike
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Deliver by")
                        .font(.caption.weight(.semibold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Color.textTertiary)

                    channelRow("Push notifications", systemImage: "app.badge", isOn: $viaPush)
                    channelRow("Email", systemImage: "envelope", isOn: $viaEmail)

                    if !viaPush && !viaEmail {
                        Text("With both off, these only show in your in-app inbox.")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            loadPreferences()
            Task { await notifications.refreshStatus() }
        }
        .onChange(of: store.myProfile) { _, _ in loadPreferences() }
    }

    // MARK: - Rows

    private func eventRow(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                isOn.wrappedValue = newValue
                handleChange()
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .nativeToggle()
    }

    private func channelRow(_ title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                isOn.wrappedValue = newValue
                handleChange()
            }
        )) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DS.Color.textPrimary)
        }
        .nativeToggle()
    }

    private var permissionWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bell.slash")
                    .foregroundStyle(.orange)
                Text("Notifications are off in iOS Settings")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
            }

            Text("Push is on here, but iOS is blocking it. Turn it back on in Settings.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

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
        mealInvite = profile.notifyMealInvite
        mealRating = profile.notifyMealRating
        partyInvite = profile.notifyPartyInvite
        partyActivity = profile.notifyPartyActivity
        recipeLike = profile.notifyRecipeLike
        viaPush = profile.notifyViaPush
        viaEmail = profile.notifyViaEmail
        hasLoaded = true
    }

    private func handleChange() {
        guard hasLoaded else { return }

        Task {
            await store.updateNotificationPreferences(
                mealInvite: mealInvite,
                mealRating: mealRating,
                partyInvite: partyInvite,
                partyActivity: partyActivity,
                recipeLike: recipeLike,
                viaPush: viaPush,
                viaEmail: viaEmail
            )
        }

        // Only meaningful once the user wants push for something.
        guard viaPush, anyEventOn else { return }

        switch notifications.authorizationStatus {
        case .notDetermined:
            // First time only — iOS shows the system prompt exactly once, ever.
            Task { await notifications.requestAuthorization() }
        case .authorized, .provisional:
            UIApplication.shared.registerForRemoteNotifications()
        default:
            // .denied / .ephemeral — the warning banner points the user to Settings.
            break
        }
    }
}
