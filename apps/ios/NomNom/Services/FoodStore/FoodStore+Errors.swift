import Foundation
import Supabase

/// A store failure already put into words (`FoodStore.errorMessage`), thrown so a
/// `FormSession.save` commit can treat every store API the same way.
struct StoreError: LocalizedError {
    let errorDescription: String?
}

extension FoodStore {

    /// Turns the store's last `errorMessage` into a thrown error and clears it, so
    /// `Bool` / `Void` / optional store APIs can be used inside a `FormSession.save`
    /// commit. Pass `succeeded: false` when the API reported failure; it then throws
    /// even if no message was set.
    func throwIfFailed(_ succeeded: Bool = true) throws {
        if let message = errorMessage {
            errorMessage = nil
            throw StoreError(errorDescription: message)
        }
        if !succeeded {
            throw StoreError(errorDescription: "Something went wrong. Please try again.")
        }
    }

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

        if let functionsError = error as? FunctionsError {
            switch functionsError {
            case .httpError(let code, let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["error"] as? String {
                    return formatGatewayError(msg, code: code)
                }
                if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    return formatGatewayError(text, code: code)
                }
                return "Server error (\(code)). Please try again."
            case .relayError:
                return "Could not connect to the cloud function. Check that Supabase is running."
            @unknown default:
                break
            }
        }

        let text = error.localizedDescription.lowercased()
        if text.contains("could not connect") || text.contains("offline")
            || text.contains("network") || text.contains("connection")
            || text.contains("appears to be offline") {
            return "Can't reach the server. Check your connection or local Supabase."
        }

        return error.localizedDescription
    }

    private static func formatGatewayError(_ raw: String, code: Int) -> String {
        let lower = raw.lowercased()
        if code == 401 || lower.contains("unauthorized") || lower.contains("api key") {
            return "AI Gateway authentication error. Please verify the VERCEL_AI_GATEWAY secret."
        }
        if code == 429 || lower.contains("rate limit") || lower.contains("quota") {
            return "The AI service is currently busy. Please wait a moment and try again."
        }
        if code == 502 || code == 503 || lower.contains("bad gateway") {
            return "Could not reach the AI model. Please try again."
        }
        if lower.contains("json") || lower.contains("parse") {
            return "Could not clearly identify a recipe in these photos. Try taking well-lit photos closer to the text."
        }
        return raw
    }
}
