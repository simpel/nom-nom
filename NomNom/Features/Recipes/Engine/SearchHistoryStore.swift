import Foundation
import SwiftUI

/// Observable store managing persistent recent search queries.
@Observable
@MainActor
final class SearchHistoryStore {
    static let shared = SearchHistoryStore()

    private let userDefaultsKey = "nomnom.search.recent_queries"
    private let maxHistoryCount = 10

    var recentQueries: [String] = []

    init() {
        load()
    }

    func addQuery(_ rawQuery: String) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        recentQueries.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        recentQueries.insert(query, at: 0)

        if recentQueries.count > maxHistoryCount {
            recentQueries = Array(recentQueries.prefix(maxHistoryCount))
        }
        persist()
    }

    func removeQuery(_ query: String) {
        recentQueries.removeAll { $0 == query }
        persist()
    }

    func clearAll() {
        recentQueries.removeAll()
        persist()
    }

    private func load() {
        if let saved = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            recentQueries = saved
        }
    }

    private func persist() {
        UserDefaults.standard.set(recentQueries, forKey: userDefaultsKey)
    }
}
