import Foundation

/// Static credentials configured for App Store Review and testing.
///
/// Apple reviewers test on physical hardware without access to external email
/// inboxes. Following the industry standard, `app@nomnom.casa` with static code
/// `123456` bypasses OTP delivery and signs in with a fixed password against
/// Supabase Auth.
enum ReviewerAccount {
    static let email = "app@nomnom.casa"
    static let code = "123456"
    static let password = "NomNomAppleReview2025!"

    static func isReviewerEmail(_ address: String) -> Bool {
        address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == email
    }

    static func isReviewerCode(_ input: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines) == code
    }
}
