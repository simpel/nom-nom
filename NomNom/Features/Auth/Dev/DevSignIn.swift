import Foundation

#if DEBUG
/// Signs in without typing, for local development only.
///
/// From Xcode: the shared scheme passes `-dev-sign-in cook@foodlog.test`, so
/// ⌘R lands on the Log tab already signed in. From the command line:
///
///     xcrun simctl launch <device> se.joelsanden.nomnom \
///         -dev-sign-in cook@foodlog.test
///
/// The address is optional — bare `-dev-sign-in` uses ``defaultEmail``.
///
/// Two routes, tried in order:
///
/// 1. **Admin.** The local stack ships a fixed `service_role` key, so the dev
///    user can be created (or have a known password set on it) outright and
///    signed in with `grant_type=password`. No mail, no polling, no six digits —
///    one round trip, and it works the same whether the account already exists.
/// 2. **Mailpit.** If that route fails for any reason, fall back to the real
///    thing: ask for a code, read it back out of the mailbox on :54324 and
///    submit it. Slower, but it exercises the flow a person actually uses.
///
/// Both refuse to run against anything but loopback, so this cannot be pointed
/// at a real project even by accident, and the whole file is compiled out of
/// release builds.
enum DevSignIn {

    /// Who you are when `-dev-sign-in` is passed without an address. Matches the
    /// account the README and `DevSelfCheck` use.
    static let defaultEmail = "cook@foodlog.test"

    static var requestedEmail: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-dev-sign-in") else { return nil }
        let next = arguments.index(after: flag)
        // A following argument that starts with "-" is the next flag, not an
        // address, so `-dev-sign-in -seed-sample-data` means "the usual account".
        guard next < arguments.endIndex, !arguments[next].hasPrefix("-") else { return defaultEmail }
        return arguments[next]
    }

    private static var isLocalStack: Bool {
        let host = SupabaseConfig.url.host() ?? ""
        return host == "127.0.0.1" || host == "localhost" || host == "::1"
    }

    private static let mailpit = URL(string: "http://127.0.0.1:54324")!

    @MainActor
    static func runIfRequested(_ auth: AuthController) async {
        guard let email = requestedEmail else { return }
        guard isLocalStack else {
            print("[DevSignIn] refusing to run: \(SupabaseConfig.url) is not the local stack")
            return
        }

        // Drop any existing session first. "Sign in as this person" should mean
        // that even when somebody else is already signed in — and the session
        // outlives the app container, so after a `db reset` the keychain still
        // holds a perfectly unexpired token for a user id that no longer exists.
        // Left in place it shows the tabs and then fails every write on a foreign
        // key against auth.users.
        try? await supabase.auth.signOut()

        if await signInWithFixedPassword(as: email) {
            print("[DevSignIn] signed in as \(email)")
            return
        }

        print("[DevSignIn] admin route unavailable, falling back to Mailpit")
        await signInThroughMailpit(as: email, auth)
    }

    // MARK: - The fast route: admin API + a known password

    /// The CLI's fixed local `service_role` key — the same demo JWT family as the
    /// publishable key in ``SupabaseConfig``, baked into the CLI and valid only
    /// against localhost. It is a real service key, so it stays in this file:
    /// `#if DEBUG` plus the loopback check above are what keep it harmless.
    private static let localServiceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

    /// Not a secret in any meaningful sense: it is only ever set on accounts in a
    /// database that lives in a container on this machine.
    private static let devPassword = "nomnom-dev-password"

    private struct AdminUser: Decodable {
        let id: String
        let email: String?
    }

    private struct AdminUserList: Decodable {
        let users: [AdminUser]
    }

    /// Makes sure `email` exists with a known password, then signs in with it.
    ///
    /// `email_confirm: true` on both paths, because an unconfirmed address cannot
    /// use `grant_type=password` — and confirmation here is meaningless anyway,
    /// there is nobody to prove they own `@foodlog.test`.
    private static func signInWithFixedPassword(as email: String) async -> Bool {
        guard await ensureAccount(email) else { return false }

        do {
            try await supabase.auth.signIn(email: email, password: devPassword)
            return true
        } catch {
            print("[DevSignIn] password sign-in refused: \(error.localizedDescription)")
            return false
        }
    }

    /// Makes sure `email` has an account on the local stack, creating it if it has
    /// none and giving it a known password either way.
    ///
    /// `DevSelfCheck` needs this too: it invites a second person and then asserts
    /// the invite resolved to an account, which only holds if that account exists.
    /// It used to rely on one left behind by an earlier run, so the check passed on
    /// a database that happened to have been used before and failed on a freshly
    /// reset one — a test with a precondition it does not establish.
    @discardableResult
    static func ensureAccount(_ email: String) async -> Bool {
        guard isLocalStack else { return false }

        if let existing = await adminUser(for: email) {
            // The account may have been created by the OTP flow and have no password
            // at all, so set one rather than assuming.
            return await admin(
                "admin/users/\(existing.id)",
                method: "PUT",
                body: ["password": devPassword, "email_confirm": true]
            )
        }
        return await admin(
            "admin/users",
            method: "POST",
            body: ["email": email, "password": devPassword, "email_confirm": true]
        )
    }

    private static func adminUser(for email: String) async -> AdminUser? {
        guard let encoded = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(SupabaseConfig.url)/auth/v1/admin/users?filter=\(encoded)&per_page=50")
        else { return nil }

        guard let list: AdminUserList = await fetch(adminRequest(url, method: "GET")) else { return nil }
        // `filter` is a substring search, so "cook@foodlog.test" would also match
        // "not-cook@foodlog.test". Pick the exact one.
        return list.users.first { $0.email?.caseInsensitiveCompare(email) == .orderedSame }
    }

    /// POST/PUT against the admin API. Returns whether it was accepted.
    private static func admin(_ path: String, method: String, body: [String: Any]) async -> Bool {
        guard let url = URL(string: "\(SupabaseConfig.url)/auth/v1/\(path)"),
              let payload = try? JSONSerialization.data(withJSONObject: body)
        else { return false }

        var request = adminRequest(url, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let status = (response as? HTTPURLResponse)?.statusCode
        else { return false }
        return (200..<300).contains(status)
    }

    private static func adminRequest(_ url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(localServiceRoleKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(localServiceRoleKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - The fallback route: the real code, read out of Mailpit

    @MainActor
    private static func signInThroughMailpit(as email: String, _ auth: AuthController) async {
        // Note what's already in the mailbox, so a code left over from an earlier
        // run can't be mistaken for this one's.
        let before = await newestMessageID(for: email)

        await auth.sendCode(to: email)
        guard auth.pendingEmail != nil else {
            print("[DevSignIn] could not request a code: \(auth.errorMessage ?? "unknown")")
            return
        }

        for _ in 0..<40 {
            try? await Task.sleep(for: .milliseconds(250))
            guard let latest = await newestMessageID(for: email), latest != before else { continue }
            guard let code = await code(inMessage: latest) else { continue }
            await auth.verify(code: code)
            if auth.userID != nil {
                print("[DevSignIn] signed in as \(email)")
            } else {
                print("[DevSignIn] code \(code) rejected: \(auth.errorMessage ?? "unknown")")
            }
            return
        }
        print("[DevSignIn] no code arrived in Mailpit for \(email)")
    }

    // MARK: - Mailpit

    private struct MessageList: Decodable {
        struct Message: Decodable {
            struct Address: Decodable { let Address: String }
            let ID: String
            let To: [Address]?
        }
        let messages: [Message]
    }

    private struct MessageBody: Decodable {
        let Text: String?
    }

    private static func newestMessageID(for email: String) async -> String? {
        guard let url = URL(string: "/api/v1/messages?limit=50", relativeTo: mailpit) else { return nil }
        guard let list: MessageList = await fetch(URLRequest(url: url)) else { return nil }
        // Mailpit returns newest first.
        return list.messages.first { message in
            message.To?.contains { $0.Address.caseInsensitiveCompare(email) == .orderedSame } ?? false
        }?.ID
    }

    private static func code(inMessage id: String) async -> String? {
        guard let url = URL(string: "/api/v1/message/\(id)", relativeTo: mailpit) else { return nil }
        guard let body: MessageBody = await fetch(URLRequest(url: url)), let text = body.Text else { return nil }
        let pattern = try? NSRegularExpression(pattern: "\\b\\d{6}\\b")
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = pattern?.firstMatch(in: text, range: range),
              let matched = Range(match.range, in: text) else { return nil }
        return String(text[matched])
    }

    private static func fetch<T: Decodable>(_ request: URLRequest) async -> T? {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
#endif
