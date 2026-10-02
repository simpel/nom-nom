import SwiftUI

/// How a new account gets its dinner party: start one, or join one with an invite.
enum OnboardingPartyChoice {
    case create
    case join
}

/// Onboarding step that puts every account in a dinner party: a centred PageHeader,
/// then the party name (start one) or the invite code (join one), and a `secondary
/// ghost` AppButton to switch between the two.
struct OnboardingPartyStep: View {
    @Binding var choice: OnboardingPartyChoice
    @Binding var partyName: String
    @Binding var inviteCode: String
    var codeError: String?

    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            switch choice {
            case .create:
                PageHeader(
                    "Start your dinner party",
                    subtitle: "The people you cook for and eat with. You can invite them once you're in.",
                    align: .center
                )
                Input(label: "Party name", placeholder: "The Friday Feast Club", text: $partyName)
                AppButton("I have an invite", variant: .secondary, appearance: .ghost) {
                    withAnimation(DS.Motion.layout) { choice = .join }
                }
            case .join:
                PageHeader(
                    "Join your dinner party",
                    subtitle: "Paste the invite code or link someone sent you.",
                    align: .center
                )
                Input(
                    label: "Invite code",
                    placeholder: "ABCD2345",
                    text: $inviteCode,
                    clearable: true,
                    error: codeError
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                AppButton("Start a new party instead", variant: .secondary, appearance: .ghost) {
                    withAnimation(DS.Motion.layout) { choice = .create }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var choice = OnboardingPartyChoice.create
    @Previewable @State var name = ""
    @Previewable @State var code = ""
    NomNomPreview { _ in
        OnboardingPartyStep(choice: $choice, partyName: $name, inviteCode: $code)
            .padding(DS.Spacing.gutter)
    }
}
