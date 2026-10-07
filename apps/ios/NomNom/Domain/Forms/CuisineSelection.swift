import Foundation

/// The cuisines picked for a recipe in CuisinePickerSheet: preset cuisines by lowercased
/// name, plus free text for the rest. Stored on the recipe as one comma-separated string.
struct CuisineSelection: SheetForm {
    var selected: Set<String> = []
    var customText: String = ""
}

extension CuisineSelection {
    /// Splits a stored cuisine string into preset matches and free text.
    init(_ value: String?) {
        let parts = Cuisine.parseMultiple(from: value)
        selected = Set(parts.compactMap { Cuisine.matching(from: $0)?.rawValue.lowercased() })
        customText = parts.filter { Cuisine.matching(from: $0) == nil }.joined(separator: ", ")
    }

    func contains(_ name: String) -> Bool {
        selected.contains(name.lowercased())
    }

    mutating func toggle(_ name: String) {
        let key = name.lowercased()
        if selected.contains(key) { selected.remove(key) } else { selected.insert(key) }
    }

    /// The stored string: presets in `Cuisine.allCases` order, then free text not already
    /// picked; nil when nothing is chosen.
    var value: String? {
        var results = Cuisine.allCases.map(\.rawValue).filter { selected.contains($0.lowercased()) }
        for part in Cuisine.parseMultiple(from: customText)
        where !results.contains(where: { $0.lowercased() == part.lowercased() }) {
            results.append(part)
        }
        return results.isEmpty ? nil : results.joined(separator: ", ")
    }
}
