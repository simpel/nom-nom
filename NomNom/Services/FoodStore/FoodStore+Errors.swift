import Foundation
import Supabase

extension FoodStore {

    static func describe(_ error: Error) -> String {
        if let error = error as? PostgrestError {
            switch error.code {
            case "42501":
                return "The server refused that — you don't have access to it."
            case "23505":
                return "That already exists."
            case "23514":
                return "The server rejected those values."
            default:
                return error.message
            }
        }
        let text = error.localizedDescription.lowercased()
        if text.contains("could not connect") || text.contains("offline")
            || text.contains("network") || text.contains("connection")
            || text.contains("appears to be offline") {
            return "Can't reach the server. Check that Supabase is running."
        }
        return error.localizedDescription
    }
}
