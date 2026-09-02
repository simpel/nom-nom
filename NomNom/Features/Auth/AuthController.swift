import Foundation
import Observation
import Supabase

/// Session state for the whole app.
///
/// Email one-time code rather than Sign in with Apple: Apple's flow needs a paid
/// developer account to get a signing identity, and there isn't one here, so it
/// could be written but never run. A six-digit code needs nothing but a mail
/// server and works identically against the local stack and the hosted project.
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
    private(set) var isWorking = false
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

    // MARK: - Lifecycle

    /// Starts mirroring the client's session into `phase`.
    ///
    /// `authStateChanges` emits `.initialSession` as soon as it is subscribed to,
    /// which is what restores a previous sign-in on launch, so there is no separate
    /// "do we have a session" query to make.
    func start() {
        guard listener == nil else { return }
        listener = Task { [weak self] in
            for await (event, session) in supabase.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .signedOut:
                    self.phase = .signedOut
                    self.step = .email
                default:
                    // A stored session can come back already expired; treating that
                    // as signed in shows the tabs and then fails every request.
                    if let session, !session.isExpired {
                        self.phase = .signedIn(userID: session.user.id)
                        self.step = .email
                    } else if case .initialSession = event {
                        self.phase = .signedOut
                    }
                }
            }
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

        do {
            // shouldCreateUser: signing in and signing up are the same gesture here
            // — there is no separate registration step, and the trigger on
            // auth.users creates the profile and claims any waiting invites.
            try await supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
            step = .code(sentTo: email)
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    func verify(code rawCode: String) async {
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
            // `.email` covers both halves of the flow. GoTrue mails a signup
            // confirmation to an address it has never seen and a magic link to one
            // it has, and verifying with the generic email type accepts either —
            // so the client doesn't have to know whether this is a new account.
            try await supabase.auth.verifyOTP(email: email, token: code, type: .email)
            // `authStateChanges` moves `phase` for us.
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    /// Back to the address field, e.g. after a typo in the email.
    func startOver() {
        step = .email
        errorMessage = nil
    }

    func signOut() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await supabase.auth.signOut()
        } catch {
            // A failed sign-out is usually the network, and leaving the user
            // apparently signed in with no way back is worse than dropping the
            // local session and letting the next launch sort it out.
            phase = .signedOut
            step = .email
        }
    }

    /// Deletes this account and everything in it, permanently.
    ///
    /// Required by App Store Review Guideline 5.1.1(v) — an app that creates
    /// accounts has to let a person delete one without leaving it.
    ///
    /// The work happens in the `delete-account` Edge Function, because removing an
    /// auth user needs the service role key and that must never ship inside an
    /// app. Note that this call carries no argument: the function reads the
    /// account to delete out of the caller's own token, so there is nothing here
    /// to name and therefore nothing to get wrong.
    ///
    /// Returns whether it worked, so the view can stay put and show the error
    /// rather than dismissing as though something had happened.
    @discardableResult
    func deleteAccount() async -> Bool {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await supabase.functions.invoke("delete-account")
        } catch {
            errorMessage = Self.describeDeletion(error)
            return false
        }

        // The account is gone, so the stored session is now a token for a user
        // that no longer exists. `.local` because the default `.global` asks the
        // server to revoke every session for this account, which is a request
        // made *as* the deleted user and fails — leaving a signed-in-looking app
        // whose every request 401s. Dropping the session locally is the whole job.
        try? await supabase.auth.signOut(scope: .local)
        phase = .signedOut
        step = .email
        return true
    }

    // MARK: - Errors

    /// A failed deletion is worth its own wording. The generic handler below is
    /// tuned for GoTrue's sign-in errors and would render a function failure as
    /// "Edge Function returned a non-2xx status code: 500", which tells a person
    /// nothing about whether their account still exists. It does.
    private static func describeDeletion(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("could not connect") || text.contains("offline")
            || text.contains("network") || text.contains("connection") {
            return "Can't reach the server, so nothing was deleted. Try again when you're back online."
        }
        // Not "nothing was removed": the function clears photos before it removes
        // the user, so a failure at the last step leaves those already gone. What
        // is true either way is that the account survived, which is what the
        // person needs to know — and a retry is safe, there is simply less to do.
        return "Couldn't delete your account — it's still there. Please try again."
    }

    /// GoTrue's raw messages are aimed at developers. These are the three a person
    /// hits in normal use.
    private static func describe(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("expired") || text.contains("invalid") {
            return "That code didn't work. It may have expired — send a new one."
        }
        if text.contains("rate") || text.contains("too many") || text.contains("429") {
            return "Too many attempts. Wait a minute and try again."
        }
        if text.contains("could not connect") || text.contains("offline")
            || text.contains("network") || text.contains("connection") {
            return "Can't reach the server. Check that Supabase is running."
        }
        return error.localizedDescription
    }
}
