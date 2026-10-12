import Foundation
import Supabase

/// Sign in with Apple and the email one-time code flow.
extension AuthController {
    // MARK: - Sign in with Apple

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            // fullName is provided only on the first sign-in (account creation),
            // so we update profile metadata when present.
            if let fullName {
                let formatted = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default).trimmingCharacters(in: .whitespacesAndNewlines)
                if !formatted.isEmpty {
                    _ = try? await supabase.auth.update(
                        user: UserAttributes(data: ["full_name": .string(formatted)])
                    )
                }
            }

            completeSignIn(userID: session.user.id)
        } catch {
            #if DEBUG
            print("Sign in with Apple error: \(error)")
            #endif
            errorMessage = Self.describe(error)
        }
    }

    // MARK: - Signing in

    func sendCode(to rawEmail: String) async {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@"), !email.hasPrefix("@"), !email.hasSuffix("@") else {
            errorMessage = "That doesn't look like an email address."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        // The reviewer test account uses a static code and does not dispatch email.
        if ReviewerAccount.isReviewerEmail(email) {
            awaitCode(sentTo: email)
            return
        }

        do {
            // shouldCreateUser: signing in and signing up are the same gesture here
            // — there is no separate registration step, and the trigger on
            // auth.users creates the profile and claims any waiting invites.
            try await supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
            awaitCode(sentTo: email)
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func verify(code rawCode: String) async {
        guard !isWorking else { return }
        guard case .code(let email) = step else { return }
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count >= 6 else {
            errorMessage = "The code is six digits."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            if ReviewerAccount.isReviewerEmail(email) {
                guard ReviewerAccount.isReviewerCode(code) else {
                    errorMessage = "That code didn't work. Please check and try again."
                    return
                }
                let session = try await supabase.auth.signIn(email: email, password: ReviewerAccount.password)
                completeSignIn(userID: session.user.id)
                return
            }

            // `.email` covers both halves of the flow. GoTrue mails a signup
            // confirmation to an address it has never seen and a magic link to one
            // it has, and verifying with the generic email type accepts either —
            // so the client doesn't have to know whether this is a new account.
            let authResponse = try await supabase.auth.verifyOTP(email: email, token: code, type: .email)
            completeSignIn(userID: authResponse.user.id)
        } catch {
            #if DEBUG
            print("Auth verification error: \(error)")
            #endif
            errorMessage = Self.describe(error)
        }
    }
}
