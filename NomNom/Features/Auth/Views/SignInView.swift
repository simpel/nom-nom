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
                VStack(spacing: 24) {
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
                .padding(24)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .background(DS.Color.bg)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Nom Nom")
                .font(AppTypography.displayXL)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Keep track of what you cooked, whether the kids ate it, and what to cook next.")
                .font(.subheadline)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
        .padding(.bottom, 8)
    }

    // MARK: - Step one

    private var emailStep: some View {
        VStack(spacing: 14) {
            TextField("you@example.com", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.go)
                .onSubmit(send)

            Button(action: send) {
                if auth.isWorking {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Email me a code").frame(maxWidth: .infinity)
                }
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
                .textFieldStyle(.roundedBorder)
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
                if auth.isWorking {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Sign in").frame(maxWidth: .infinity)
                }
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
    /// The local stack does not send mail — it captures it. Easy to forget, and the
    /// symptom is sitting waiting for an email that will never arrive.
    private var developmentHint: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Local development", systemImage: "hammer.fill")
                .font(.caption.weight(.semibold))
            Text("This build talks to the local Supabase stack. Codes don't get sent — read them in Mailpit at 127.0.0.1:54324.")
                .font(.caption2)
        }
        .foregroundStyle(DS.Color.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(DS.Color.sunken)
        }
    }
    #endif
}
