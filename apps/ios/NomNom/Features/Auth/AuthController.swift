import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Supabase

/// Session state for the whole app.
///
/// Supports native Sign in with Apple and email one-time code (OTP).
@MainActor
@Observable
final class AuthController {

    enum Phase: Equatable {
        /// Before the stored session (if any) has been read back.
        case loading
        case signedOut
        case signedIn(userID: UUID)
    }

    /// Where the sign-in form is: collecting an address, or collecting the code
    /// that was just mailed to it.
    enum Step: Equatable {
        case email
        case code(sentTo: String)
    }

    private(set) var phase: Phase = .loading
    private(set) var step: Step = .email
    /// True while a sign-in, sign-out or deletion is in flight. Set by the extensions
    /// in `AuthController+SignIn.swift` and `AuthController+Account.swift`.
    var isWorking = false
    var errorMessage: String?

    private var listener: Task<Void, Never>?

    var userID: UUID? {
        if case .signedIn(let id) = phase { return id }
        return nil
    }

    /// Address the code went to, for the "we sent a code to …" line.
    var pendingEmail: String? {
        if case .code(let address) = step { return address }
        return nil
    }

    init(phase: Phase = .loading, step: Step = .email) {
        self.phase = phase
        self.step = step
    }

    static var preview: AuthController {
        AuthController(phase: .signedIn(userID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!))
    }

    /// Moves to the signed-in phase, back on the address step for the next sign-out.
    func completeSignIn(userID: UUID) {
        phase = .signedIn(userID: userID)
        step = .email
    }

    /// Drops to the signed-out phase on the address step.
    func completeSignOut() {
        phase = .signedOut
        step = .email
    }

    /// Shows the code field once a code is on its way to `email`.
    func awaitCode(sentTo email: String) {
        step = .code(sentTo: email)
    }

    // MARK: - Lifecycle

    /// Starts mirroring the client's session into `phase`.
    ///
    /// `authStateChanges` emits `.initialSession` as soon as it is subscribed to,
    /// which is what restores a previous sign-in on launch, so there is no separate
    /// "do we have a session" query to make.
    func start() {
        guard listener == nil else { return }
        listener = Task { [weak self] in
            // Actively resolve the persisted session first to avoid race condition on launch
            do {
                let initialSession = try await supabase.auth.session
                if !initialSession.isExpired {
                    self?.phase = .signedIn(userID: initialSession.user.id)
                    self?.step = .email
                } else {
                    self?.phase = .signedOut
                }
            } catch {
                self?.phase = .signedOut
            }

            for await (event, session) in supabase.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .signedOut:
                    self.phase = .signedOut
                    self.step = .email
                case .initialSession:
                    if let session, !session.isExpired {
                        self.phase = .signedIn(userID: session.user.id)
                        self.step = .email
                    }
                default:
                    // A stored session can come back already expired; treating that
                    // as signed in shows the tabs and then fails every request.
                    if let session, !session.isExpired {
                        self.phase = .signedIn(userID: session.user.id)
                        self.step = .email
                    } else {
                        self.phase = .signedOut
                    }
                }
            }
        }
    }

    /// Stops mirroring the session. The listener otherwise lives as long as the controller.
    func stop() {
        listener?.cancel()
        listener = nil
    }

    /// Back to the address field, e.g. after a typo in the email.
    func startOver() {
        step = .email
        errorMessage = nil
    }
}
