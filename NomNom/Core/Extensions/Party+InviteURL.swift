import Foundation

extension Party {
    /// Standard deep link URL for joining/viewing this dinner party.
    var inviteURL: URL {
        URL(string: "nomnom://invite?party_id=\(id.uuidString)") ?? URL(string: "nomnom://party/\(id.uuidString)")!
    }

    /// App Store / web universal landing URL fallback if configured.
    var webInviteURL: URL {
        URL(string: "https://www.nomnom.casa/invite?party_id=\(id.uuidString)") ?? inviteURL
    }

    /// Default invitation message text for system share sheet (iMessage, WhatsApp, AirDrop, etc.).
    var shareMessage: String {
        "Join \(name) on Nom Nom so we can share meals, recipes, and ratings together!"
    }
}
