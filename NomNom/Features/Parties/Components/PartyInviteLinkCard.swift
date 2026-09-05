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
                        item: party.inviteURL,
                        subject: Text("Join \(party.name) on Nom Nom"),
                        message: Text(party.shareMessage)
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .fontWeight(.semibold)
                            Text("Share Link")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DS.Color.accentSoft)
                        .foregroundStyle(DS.Color.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        copyLink()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                                .fontWeight(.semibold)
                            Text(didCopy ? "Copied!" : "Copy")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(DS.Color.panel)
                        .foregroundStyle(didCopy ? DS.Color.Pine.pine600 : DS.Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .strokeBorder(DS.Color.line.opacity(0.4), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = party.inviteURL.absoluteString
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
