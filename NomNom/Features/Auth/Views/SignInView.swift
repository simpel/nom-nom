import SwiftUI

/// Two steps: type an address, then type the six digits that arrive in the inbox.
///
/// There is no password and no separate sign-up. A first-time address gets an
/// account on the spot, which is also what triggers the database to claim any meal
/// invites already waiting for that email.
struct SignInView: View {
    @Environment(AuthController.self) private var auth

    @State private var email = ""
    @State private var code = ""
    @FocusState private var focus: Field?

    private enum Field { case email, code }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.sectionLarge) {
                    header

                    switch auth.step {
                    case .email:
                        emailStep
                    case .code(let address):
                        codeStep(sentTo: address)
                    }

                    if let message = auth.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DS.Spacing.md) {
            AuthHeroArcView()
                .padding(.bottom, DS.Spacing.xs)

            Text("Nom Nom")
                .font(AppTypography.displayXL)
                .foregroundStyle(DS.Color.textPrimary)

            Text("Keep track of what you cooked, whether the kids ate it, and what to cook next.")
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DS.Spacing.screenTop)
        .padding(.bottom, DS.Spacing.xs)
    }

    // MARK: - Step one

    private var emailStep: some View {
        VStack(spacing: 14) {
            TextField("you@example.com", text: $email)
                .padding(14)
                .background(DS.Color.sunken)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.go)
                .onSubmit(send)

            Button(action: send) {
                Text("Email me a code")
                    .frame(maxWidth: .infinity)
                    .pendingState(auth.isWorking)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(auth.isWorking || email.trimmingCharacters(in: .whitespaces).isEmpty)

            Text("No password. We'll send a six-digit code — if you've never signed in before, this creates your account.")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .onAppear { focus = .email }
    }

    // MARK: - Step two

    private func codeStep(sentTo address: String) -> some View {
        VStack(spacing: 14) {
            Text("We sent a code to **\(address)**")
                .font(.subheadline)
                .multilineTextAlignment(.center)

            TextField("000000", text: $code)
                .padding(14)
                .background(DS.Color.sunken)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                }
                .font(.title2.monospacedDigit())
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focus, equals: .code)
                .onChange(of: code) { _, newValue in
                    // Keep it to six digits, then submit on its own — the keypad has
                    // no return key to submit with.
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { code = digits }
                    if digits.count == 6 { verify() }
                }

            Button(action: verify) {
                Text("Sign in")
                    .frame(maxWidth: .infinity)
                    .pendingState(auth.isWorking)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(auth.isWorking || code.count < 6)

            Button("Use a different address") {
                code = ""
                auth.startOver()
                focus = .email
            }
            .font(.footnote)

            #if DEBUG
            if ReviewerAccount.isReviewerEmail(address) {
                Button("Fill reviewer code (\(ReviewerAccount.code))") {
                    code = ReviewerAccount.code
                }
                .font(.caption)
            }
            #endif
        }
        .onAppear { focus = .code }
    }

    // MARK: - Actions

    private func send() {
        Task { await auth.sendCode(to: email) }
    }

    private func verify() {
        Task { await auth.verify(code: code) }
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
