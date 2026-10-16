import Foundation
import Supabase

/// Sign-out and account deletion.
extension AuthController {
    func signOut() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await supabase.auth.signOut()
        } catch {
            // A failed sign-out is usually the network, and leaving the user
            // apparently signed in with no way back is worse than dropping the
            // local session and letting the next launch sort it out.
            completeSignOut()
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
        completeSignOut()
        noticeMessage = "Your account was deleted."
        return true
    }
}
