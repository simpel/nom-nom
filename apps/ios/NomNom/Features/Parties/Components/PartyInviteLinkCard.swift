import SwiftUI

/// The party's invite link in a SectionCard: one sentence, the invite code (typed in
/// onboarding's "I have an invite") as a ListRow value, then Share (`primary soft`,
/// the system share sheet) and Copy (`secondary outline`) side by side.
struct PartyInviteLinkCard: View {
    let party: Party

    @State private var didCopy = false

    /// How long "Copied" stays before the button reads "Copy" again (not a design value).
    private static let copiedInterval: Duration = .seconds(2)

    var body: some View {
        SectionCard("Invite link") {
            Text("Anyone with this link can view and join \(party.name).")
                .textStyle(.sansSm, tone: .secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let code = party.inviteCode {
                ListRow("Invite code", value: code)
            }

            // ScreenHeader / EmptyState action rows sit `spacing-2` apart.
            HStack(spacing: DS.Spacing.s2) {
                ShareLink(
                    item: party.webInviteURL,
                    subject: Text("Join \(party.name) on Nom Nom"),
                    message: Text(party.shareMessage)
                ) {
                    AppButtonLabel("Share link", icon: "square.and.arrow.up", appearance: .soft, fullWidth: true)
                }
                .buttonStyle(AppPressableButtonStyle())

                AppButton(
                    didCopy ? "Copied" : "Copy",
                    icon: didCopy ? "checkmark" : "doc.on.doc",
                    variant: .secondary,
                    appearance: .outline,
                    action: copyLink
                )
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = party.webInviteURL.absoluteString
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(DS.Motion.state) {
            didCopy = true
        }
        Task {
            try? await Task.sleep(for: Self.copiedInterval)
            withAnimation(DS.Motion.state) {
                didCopy = false
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyInviteLinkCard(party: party)
                .padding(DS.Spacing.gutter)
        }
    }
}
