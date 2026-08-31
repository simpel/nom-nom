import SwiftUI

/// How an eater reacted to a dish. Stored as an Int so it survives migrations.
enum Reaction: Int, Codable, CaseIterable, Identifiable, Hashable {
    case loved = 2
    case ok = 1
    case disliked = 0

    var id: Int { rawValue }

    /// Normalised 0...1 score used by the suggestion engine.
    var score: Double {
        switch self {
        case .loved: return 1.0
        case .ok: return 0.5
        case .disliked: return 0.0
        }
    }

    var emoji: String {
        switch self {
        case .loved: return "😋"
        case .ok: return "😐"
        case .disliked: return "🙅"
        }
    }

    var label: String {
        switch self {
        case .loved: return "Loved it"
        case .ok: return "It was ok"
        case .disliked: return "Not a fan"
        }
    }

    var shortLabel: String {
        switch self {
        case .loved: return "Loved"
        case .ok: return "Ok"
        case .disliked: return "Nope"
        }
    }

    var tint: Color {
        switch self {
        case .loved: return .green
        case .ok: return .orange
        case .disliked: return .red
        }
    }
}
