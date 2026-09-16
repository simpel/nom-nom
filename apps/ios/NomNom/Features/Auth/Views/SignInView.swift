import SwiftUI

/// Start page offering Sign in with Apple or Sign in with email.
struct SignInView: View {
    @Environment(AuthController.self) private var auth
    @State private var navigateToEmailSignIn = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(spacing: DS.Spacing.md) {
                    AuthHeroArcView()
                        .padding(.bottom, DS.Spacing.xs)

                    PageHeader(
                        title: "Nom Nom",
                        subtitle: "Keep track of what you cooked, whether the kids ate it, and what to cook next."
                    )
                }

                Spacer()

                VStack(spacing: 12) {
                    if let message = auth.errorMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                    }

                    // 1. Sign in with Apple (Black button with Apple logo)
                    AppleSignInButton()

                    // 2. Sign in with email (Leads to separate screen)
                    AppButton(
                        "Sign in with email",
                        variant: .neutral,
                        style: .outlined,
                        size: .xl,
                        isFullWidth: true,
                        disabled: auth.isWorking
                    ) {
                        auth.errorMessage = nil
                        navigateToEmailSignIn = true
                    }
                }
                .padding(.bottom, DS.Spacing.screenBottom)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
            .background(DS.Color.bg)
            .navigationDestination(isPresented: $navigateToEmailSignIn) {
                EmailSignInView()
            }
        }
    }
}
