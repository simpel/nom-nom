import Foundation

// MARK: - Errors

extension AuthController {
    /// A failed deletion is worth its own wording. The generic handler below is
    /// tuned for GoTrue's sign-in errors and would render a function failure as
    /// "Edge Function returned a non-2xx status code: 500", which tells a person
    /// nothing about whether their account still exists. It does.
    static func describeDeletion(_ error: Error) -> String {
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
    static func describe(_ error: Error) -> String {
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
