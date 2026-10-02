import SwiftUI

/// Start page offering Sign in with Apple or Sign in with email.
struct SignInView: View {
    @Environment(AuthController.self) private var auth
    @State private var navigateToEmailSignIn = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(spacing: DS.Spacing.s5) {
                    AppIconMark()

                    // The sign-in buttons stay at the bottom: Sign in with Apple is
                    // Apple's own control, not an AppButton the header could build.
                    PageHeader(
                        "Nom Nom",
                        subtitle: "Keep track of what you cooked, whether the kids ate it, and what to cook next.",
                        align: .center
                    )
                }

                Spacer()

                VStack(spacing: DS.Spacing.s3) {
                    if let message = auth.errorMessage {
                        Text(message)
                            .textStyle(.sansSm, tone: .secondary, align: .center)
                            .padding(.bottom, DS.Spacing.s1)
                    }

                    // 1. Sign in with Apple (Black button with Apple logo)
                    AppleSignInButton()

                    // 2. Sign in with email (Leads to separate screen)
                    AppButton(
                        "Sign in with email",
                        variant: .secondary,
                        appearance: .outline,
                        size: .lg,
                        fullWidth: true
                    ) {
                        auth.errorMessage = nil
                        navigateToEmailSignIn = true
                    }
                    .disabled(auth.isWorking)
                }
                .padding(.bottom, DS.Spacing.s11)
            }
            .padding(.horizontal, DS.Spacing.s6)
            .frame(maxWidth: DS.Container.sm)
            .frame(maxWidth: .infinity)
            .background(DS.Color.bg)
            .navigationDestination(isPresented: $navigateToEmailSignIn) {
                EmailSignInView()
            }
        }
    }
}
