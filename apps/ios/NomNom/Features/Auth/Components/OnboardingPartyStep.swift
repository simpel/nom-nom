import SwiftUI

/// How a new account gets its dinner party: start one, or accept the invites waiting for it.
enum OnboardingPartyChoice {
    case create
    case invites
}

/// Onboarding's last step, which puts every account in a dinner party: a centred
/// ScreenHeader, then either the party name (start one) or the pending invites to
/// accept or decline plus an invite-code field, and a `secondary ghost` AppButton to
/// switch between the two.
struct OnboardingPartyStep: View {
    @Binding var choice: OnboardingPartyChoice
    @Binding var partyName: String
    @Binding var inviteCode: String
    var codeError: String?
    var isAddingCode: Bool
    let joinedPartyIDs: [UUID]
    var busyInviteID: UUID?
    let onAddCode: () -> Void
    let onAccept: (PartyInvite) -> Void
    let onDecline: (PartyInvite) -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            switch choice {
            case .create:
                ScreenHeader(
                    "Start your dinner party",
                    summary: "The people you cook for and eat with. You can invite them once you're in.",
                    role: .moment
                )
                Input(label: "Party name", placeholder: "The Friday Feast Club", text: $partyName)
                AppButton("I have an invite", variant: .secondary, appearance: .ghost) {
                    withAnimation(DS.Motion.layout) { choice = .invites }
                }
            case .invites:
                ScreenHeader(
                    "Your invitations",
                    summary: "Accept the dinner parties you want to join. You can join more than one.",
                    role: .moment
                )
                OnboardingInvitesList(
                    joinedPartyIDs: joinedPartyIDs,
                    busyInviteID: busyInviteID,
                    onAccept: onAccept,
                    onDecline: onDecline
                )
                codeField
                AppButton("Start a new party instead", variant: .secondary, appearance: .ghost) {
                    withAnimation(DS.Motion.layout) { choice = .create }
                }
            }
        }
    }

    /// A code or link from someone in the party; it joins the list above as an invite.
    private var codeField: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Input(
                label: "Have an invite code?",
                placeholder: "ABCD2345",
                text: $inviteCode,
                clearable: true,
                error: codeError
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .onSubmit(onAddCode)
            AppButton("Add invite", variant: .secondary, appearance: .soft, size: .sm, isLoading: isAddingCode) {
                onAddCode()
            }
            .disabled(inviteCode.trimmedName.isEmpty)
        }
    }
}

#Preview {
    @Previewable @State var choice = OnboardingPartyChoice.invites
    @Previewable @State var name = ""
    @Previewable @State var code = ""
    NomNomPreview { _ in
        OnboardingPartyStep(
            choice: $choice, partyName: $name, inviteCode: $code, isAddingCode: false,
            joinedPartyIDs: [], onAddCode: {}, onAccept: { _ in }, onDecline: { _ in }
        )
        .padding(DS.Spacing.gutter)
    }
}
