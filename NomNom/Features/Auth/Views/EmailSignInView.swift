import SwiftUI

/// Dedicated email sign-in screen: enter email address, then verify 6-digit OTP code.
struct EmailSignInView: View {
    @Environment(AuthController.self) private var auth

    @State private var email = ""
    @State private var code = ""
    @FocusState private var emailFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.sectionLarge) {
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
            .padding(.horizontal, 24)
            .padding(.bottom, DS.Spacing.screenBottom)
            .frame(maxWidth: 460)
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
            title: auth.step == .email ? "Sign in with email" : "Check your inbox",
            subtitle: auth.step == .email
                ? "Enter your email and we'll send you a six-digit verification code."
                : "Enter the code we mailed to complete sign in."
        )
        .padding(.top, DS.Spacing.screenTop)
    }

    // MARK: - Step one: Email

    private var emailStep: some View {
        VStack(spacing: 14) {
            Input(
                "you@example.com",
                text: $email,
                size: .xl,
                shape: .capsule,
                isError: auth.errorMessage != nil,
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

            if let message = auth.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            AppButton(
                "Email me a code",
                variant: .primary,
                style: .normal,
                size: .xl,
                isFullWidth: true,
                isPending: auth.isWorking,
                disabled: auth.isWorking || email.trimmingCharacters(in: .whitespaces).isEmpty,
                action: send
            )
        }
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
        .onAppear { emailFocused = true }
    }

    // MARK: - Step two: Code

    private func codeStep(sentTo address: String) -> some View {
        VStack(spacing: 14) {
            Text("We sent a code to **\(address)**")
                .font(.subheadline)
                .multilineTextAlignment(.center)

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
            .padding(.vertical, 4)

            if auth.errorMessage != nil {
                HStack(spacing: 6) {
                    Text("The code didn't work.")
                        .foregroundStyle(DS.Color.textSecondary)

                    AppButton("Send new code", variant: .neutral, style: .ghost, size: .sm) {
                        code = ""
                        auth.errorMessage = nil
                        Task { await auth.sendCode(to: address) }
                    }
                }
                .font(.subheadline)
                .transition(.opacity)
            }

            AppButton(
                "Sign in",
                variant: .primary,
                style: .normal,
                size: .xl,
                isFullWidth: true,
                isPending: auth.isWorking,
                disabled: auth.isWorking || code.count < 6,
                action: { verify() }
            )

            AppButton(
                "Use a different address",
                variant: .neutral,
                style: .ghost,
                size: .xl,
                isFullWidth: true,
                disabled: auth.isWorking
            ) {
                code = ""
                auth.startOver()
            }

            #if DEBUG
            if ReviewerAccount.isReviewerEmail(address) {
                AppButton("Fill reviewer code (\(ReviewerAccount.code))", variant: .neutral, style: .outlined, size: .sm) {
                    code = ReviewerAccount.code
                    verify(code: ReviewerAccount.code)
                }
            }
            #endif
        }
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
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
    private var developmentHint: some View {
        Button {
            email = ReviewerAccount.email
            send()
        } label: {
            HStack {
                Text("Fill test account")
                    .font(.footnote.weight(.medium))
                Spacer()
                Text(ReviewerAccount.email)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(DS.Color.sunken)
            }
        }
        .buttonStyle(.plain)
    }
    #endif
}
