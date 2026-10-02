import SwiftUI

/// Dedicated email sign-in screen: enter email address, then verify 6-digit OTP code.
struct EmailSignInView: View {
    @Environment(AuthController.self) private var auth

    @State private var email = ""
    @State private var code = ""
    @FocusState private var emailFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s10) {
                header

                switch auth.step {
                case .email:
                    emailStep
                case .code(let address):
                    codeStep(sentTo: address)
                }

                #if DEBUG
                developmentHint
                #endif
            }
            .padding(.horizontal, DS.Spacing.s6)
            .padding(.bottom, DS.Spacing.s11)
            .frame(maxWidth: DS.Container.sm)
            .frame(maxWidth: .infinity)
        }
        .background(DS.Color.bg)
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            auth.startOver()
        }
    }

    // MARK: - Header

    private var header: some View {
        PageHeader(
            auth.step == .email ? "Sign in with email" : "Check your inbox",
            subtitle: auth.step == .email
                ? "Enter your email and we'll send you a six-digit verification code."
                : "Enter the code we mailed to complete sign in.",
            align: .center
        )
        .padding(.top, DS.Spacing.s5)
    }

    // MARK: - Step one: Email

    private var emailStep: some View {
        VStack(spacing: DS.Spacing.s3_5) {
            Input(
                "you@example.com",
                text: $email,
                error: auth.errorMessage,
                isFocused: $emailFocused
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .onSubmit(send)
            .onChange(of: email) { _, _ in
                if auth.errorMessage != nil {
                    auth.errorMessage = nil
                }
            }

            AppButton("Email me a code", size: .lg, fullWidth: true, isLoading: auth.isWorking, action: send)
                .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .animation(DS.Motion.state, value: auth.errorMessage)
        .onAppear { emailFocused = true }
    }

    // MARK: - Step two: Code

    private func codeStep(sentTo address: String) -> some View {
        VStack(spacing: DS.Spacing.s3_5) {
            Text("We sent a code to **\(address)**")
                .textStyle(.sansMd, tone: .secondary, align: .center)

            OTPCodeField(
                code: $code,
                isError: auth.errorMessage != nil,
                onComplete: { completeCode in
                    verify(code: completeCode)
                },
                onEdit: {
                    if auth.errorMessage != nil {
                        auth.errorMessage = nil
                    }
                }
            )
            .padding(.vertical, DS.Spacing.s1)

            if auth.errorMessage != nil {
                HStack(spacing: DS.Spacing.s1_5) {
                    Text("The code didn't work.")
                        .textStyle(.sansSm, tone: .secondary)

                    AppButton("Send new code", variant: .secondary, appearance: .ghost, size: .sm) {
                        code = ""
                        auth.errorMessage = nil
                        Task { await auth.sendCode(to: address) }
                    }
                }
                .transition(.opacity)
            }

            AppButton("Sign in", size: .lg, fullWidth: true, isLoading: auth.isWorking) { verify() }
                .disabled(code.count < 6)

            AppButton("Use a different address", variant: .secondary, appearance: .ghost, size: .lg, fullWidth: true) {
                code = ""
                auth.startOver()
            }
            .disabled(auth.isWorking)

            #if DEBUG
            if ReviewerAccount.isReviewerEmail(address) {
                AppButton("Fill reviewer code (\(ReviewerAccount.code))", variant: .secondary, appearance: .outline, size: .sm) {
                    code = ReviewerAccount.code
                    verify(code: ReviewerAccount.code)
                }
            }
            #endif
        }
        .animation(DS.Motion.state, value: auth.errorMessage)
    }

    // MARK: - Actions

    private func send() {
        Task { await auth.sendCode(to: email) }
    }

    private func verify(code overrideCode: String? = nil) {
        guard !auth.isWorking else { return }
        let targetCode = (overrideCode ?? code).trimmingCharacters(in: .whitespacesAndNewlines)
        guard targetCode.count >= 6 else { return }
        Task { await auth.verify(code: targetCode) }
    }

    #if DEBUG
    /// Debug-only shortcut: a pressable ListRow in a list Card.
    private var developmentHint: some View {
        Card(layout: .list) {
            ListRow("Fill test account", meta: ReviewerAccount.email) {
                email = ReviewerAccount.email
                send()
            }
        }
    }
    #endif
}
