import SwiftUI

/// A featured SectionCard inviting the viewer to accept a pending party invite.
/// Errors from accepting go to `onError`.
struct PartyJoinBanner: View {
    let party: Party
    let invite: PartyInvite
    let onError: (String) -> Void

    @Environment(FoodStore.self) private var store
    @State private var isJoining = false

    var body: some View {
        SectionCard("Invitation", variant: .primary) {
            Text("You\u{2019}ve been invited to join \(party.name).")
                .textStyle(.sansMd)
                .fixedSize(horizontal: false, vertical: true)

            AppButton("Join dinner party", icon: "checkmark", fullWidth: true, isLoading: isJoining) {
                join()
            }
        }
    }

    private func join() {
        guard !isJoining else { return }
        isJoining = true
        Task {
            await store.acceptPartyInvite(invite)
            isJoining = false
            if let message = store.errorMessage {
                onError(message)
                store.errorMessage = nil
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
