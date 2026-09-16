import SwiftUI

/// Apple HIG-aligned card for sharing a dinner party invite link via the system ShareSheet or copying to clipboard.
struct PartyInviteLinkCard: View {
    let party: Party

    @State private var didCopy = false

    var body: some View {
        SectionCard("Invite Link") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Anyone with this link can view and join \(party.name).")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                HStack(spacing: 10) {
                    ShareLink(
                        item: party.webInviteURL,
                        subject: Text("Join \(party.name) on Nom Nom"),
                        message: Text(party.shareMessage)
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.callout.weight(.semibold))
                            Text("Share Link")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .padding(.horizontal, 16)
                        .background(DS.Color.accentSoft)
                        .foregroundStyle(DS.Color.accentText)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    AppButton(
                        didCopy ? "Copied!" : "Copy",
                        systemImage: didCopy ? "checkmark" : "doc.on.doc",
                        variant: .neutral,
                        style: .outlined,
                        size: .md
                    ) {
                        copyLink()
                    }
                }
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = party.webInviteURL.absoluteString
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.2)) {
            didCopy = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                didCopy = false
            }
        }
    }
}

#Preview {
    NomNomPreview { store in
        if let party = store.parties.first {
            PartyInviteLinkCard(party: party)
                .padding()
        }
    }
}
