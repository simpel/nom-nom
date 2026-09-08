import AuthenticationServices
import CryptoKit
import SwiftUI

/// Standard "Sign in with Apple" black button.
///
/// Requests identity token with secure SHA256 hashed nonce and forwards credentials
/// to `AuthController` for Supabase authentication.
struct AppleSignInButton: View {
    @Environment(AuthController.self) private var auth
    @State private var currentNonce: String?

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            let rawNonce = generateNonce()
            currentNonce = rawNonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(rawNonce)
        } onCompletion: { result in
            handleCompletion(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(Capsule())
        .disabled(auth.isWorking)
        .opacity(auth.isWorking ? 0.6 : 1.0)
    }

    // MARK: - Handlers

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                auth.errorMessage = "Unable to process Apple credentials."
                return
            }
            guard let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8) else {
                auth.errorMessage = "Unable to retrieve Apple identity token."
                return
            }
            guard let nonce = currentNonce else {
                auth.errorMessage = "Invalid authorization state."
                return
            }

            Task {
                await auth.signInWithApple(
                    idToken: idToken,
                    nonce: nonce,
                    fullName: appleIDCredential.fullName
                )
            }

        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain {
                if nsError.code == ASAuthorizationError.canceled.rawValue {
                    return
                }
                if nsError.code == ASAuthorizationError.unknown.rawValue {
                    auth.errorMessage = "Sign in with Apple failed. If testing on a simulator, make sure you are signed in to an Apple Account in Settings."
                    return
                }
                if nsError.code == ASAuthorizationError.notHandled.rawValue || nsError.code == ASAuthorizationError.failed.rawValue {
                    auth.errorMessage = "Sign in with Apple failed. Please try again."
                    return
                }
            }
            auth.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Crypto Nonce Helpers

    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce: \(errorCode)")
        }
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
