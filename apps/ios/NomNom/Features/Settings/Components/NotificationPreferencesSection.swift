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
        VStack(alignment: .leading, spacing: DS.Spacing.block) {
            if showsPermissionWarning {
                permissionWarning
            }

            DSSection("Notifications") {
                Card(layout: .list) {
                    row("Meal invitations", meta: "Someone asks you to rate a meal", isOn: $mealInvite)
                    row("Ratings on your meals", meta: "Someone rates a dish you cooked", isOn: $mealRating)
                    row("Dinner party invitations", meta: "Someone invites you to a party", isOn: $partyInvite)
                    row("Party activity", meta: "Someone joins or follows your party", isOn: $partyActivity)
                    row("Recipe likes", meta: "Someone likes one of your recipes", isOn: $recipeLike)
                }
            }

            DSSection("Deliver by") {
                Card(layout: .list) {
                    row("Push notifications", isOn: $viaPush)
                    row("Email", isOn: $viaEmail)
                }
                if !viaPush && !viaEmail {
                    Text("With both off, these only show in your in-app inbox.")
                        .textStyle(.sansSm, tone: .secondary)
                        .padding(.horizontal, DS.Spacing.sectionInset)
                        .padding(.top, DS.Spacing.s2)
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

    /// ListRow Toggle shape; every switch saves the whole set.
    private func row(_ title: String, meta: String? = nil, isOn: Binding<Bool>) -> ListRow {
        ListRow(title, meta: meta, trailing: .toggle(Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                isOn.wrappedValue = newValue
                handleChange()
            }
        )))
    }

    private var permissionWarning: some View {
        Card(spacing: DS.Spacing.s2) {
            Text("Notifications are off in iOS Settings").textStyle(.sansMd, weight: .semibold)
            Text("Push is on here, but iOS is blocking it. Turn it back on in Settings.")
                .textStyle(.sansSm, tone: .secondary)
            AppButton("Open iOS Settings", variant: .secondary, appearance: .outline, size: .sm) {
                notifications.openSystemSettings()
            }
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
