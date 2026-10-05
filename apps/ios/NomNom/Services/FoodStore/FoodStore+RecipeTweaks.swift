import Foundation
import Supabase

/// "Make it land next time" tips for a party meal, from the `suggest-recipe-tweaks` edge
/// function (Nom Nom Pro). The function keeps its own cache per meal; the store keeps the
/// last answer in memory so reopening the sheet doesn't call it again.
/// Why the tips didn't load, as the sheet explains it.
enum RecipeTweaksFailure: Error, Equatable {
    /// No connection, or the function isn't reachable.
    case offline
    /// The account has no Nom Nom Pro on the server (402).
    case notPro
    /// The meal has no ratings yet (409) or no party (404).
    case nothingToGoOn
    /// The model or gateway failed (5xx).
    case unavailable

    init(_ error: Error) {
        if case FunctionsError.httpError(let code, _) = error {
            switch code {
            case 402: self = .notPro
            case 404, 409: self = .nothingToGoOn
            default: self = .unavailable
            }
        } else {
            self = .offline
        }
    }

    var title: String {
        switch self {
        case .offline: return "Couldn\u{2019}t reach Nom Nom"
        case .notPro: return "Tips need Nom Nom Pro"
        case .nothingToGoOn: return "Not enough to go on yet"
        case .unavailable: return "Couldn\u{2019}t work out what to change"
        }
    }

    var message: String {
        switch self {
        case .offline: return "Check your connection and try again."
        case .notPro: return "Your account doesn\u{2019}t have Pro on the server yet. Restore your purchase and try again."
        case .nothingToGoOn: return "Tips come once someone at the table has rated the meal."
        case .unavailable: return "This happens now and then. Try again in a moment."
        }
    }
}

extension FoodStore {

    private struct TweaksRequest: Encodable {
        let meal_id: String
        let force: Bool
    }

    /// The party a meal's tips and note belong to: the current party if the meal is in
    /// it, else the meal's first party. Nil for a meal eaten with no party.
    func tweaksParty(forMeal meal: Meal) -> Party? {
        let parties = parties(forMeal: meal.id)
        if let current = currentParty, parties.contains(where: { $0.id == current.id }) {
            return current
        }
        return parties.first
    }

    /// The tips for this meal, from memory unless `force` asks the function to regenerate.
    /// Throws a `RecipeTweaksFailure`.
    func recipeTweaks(forMeal meal: Meal, force: Bool = false) async throws -> RecipeTweaks {
        if !force, let cached = recipeTweaksByMeal[meal.id] { return cached }
        let tweaks: RecipeTweaks
        do {
            tweaks = try await supabase.functions.invoke(
                "suggest-recipe-tweaks",
                options: FunctionInvokeOptions(body: TweaksRequest(meal_id: meal.id.uuidString.lowercased(), force: force))
            )
        } catch {
            Self.log.error("suggest-recipe-tweaks failed: \(error.localizedDescription, privacy: .public)")
            throw RecipeTweaksFailure(error)
        }
        recipeTweaksByMeal[meal.id] = tweaks
        return tweaks
    }
}
