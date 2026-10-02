import Foundation

/// Where an incoming URL (universal link, custom scheme or notification) points.
enum DeepLink: Equatable {
    case party(UUID)
    case rateMeal(UUID)
    case viewMeal(UUID)

    /// The tab that owns the destination.
    var tab: Int {
        switch self {
        case .party: return 1
        case .rateMeal, .viewMeal: return 0
        }
    }

    /// Parses `nomnom.casa` universal links and `nomnom://` URLs.
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }

        let pathParts = url.pathComponents.filter { $0 != "/" }
        let isUniversalLink = url.host == "www.nomnom.casa" || url.host == "nomnom.casa"
        let hostOrPath = isUniversalLink ? (pathParts.first ?? "") : (url.host ?? "")
        let queryItems = components.queryItems ?? []

        // 1. Party links: /invite?party_id=... or /party?id=... or /party/<uuid>
        let partyQuery = queryItems.first(where: { $0.name == "party_id" })?.value
            ?? (hostOrPath == "party" ? queryItems.first(where: { $0.name == "id" })?.value : nil)
        if let partyQuery, let uuid = UUID(uuidString: partyQuery) {
            self = .party(uuid)
            return
        }
        if hostOrPath == "party", let uuid = pathParts.lazy.compactMap(UUID.init(uuidString:)).first {
            self = .party(uuid)
            return
        }

        // 2. Meal links: /rate-meal?id=... or /invite?meal_id=... or /meal?id=...
        if let idString = queryItems.first(where: { $0.name == "id" || $0.name == "meal_id" })?.value,
           let uuid = UUID(uuidString: idString) {
            self = (hostOrPath == "rate-meal" || hostOrPath == "invite") ? .rateMeal(uuid) : .viewMeal(uuid)
            return
        }

        // 3. /meal/<uuid>/rate or /meal/<uuid>
        if let uuid = pathParts.lazy.compactMap(UUID.init(uuidString:)).first {
            self = url.path.contains("rate") ? .rateMeal(uuid) : .viewMeal(uuid)
            return
        }

        // 4. nomnom://<uuid> (fallback for legacy meal view)
        if !isUniversalLink, let host = url.host, let uuid = UUID(uuidString: host) {
            self = .viewMeal(uuid)
            return
        }
        return nil
    }
}
