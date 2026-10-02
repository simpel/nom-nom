import SwiftUI

/// Title field that autofills from dishes we've already cooked.
///
/// Three things keep the naming consistent:
///  1. a ranked suggestion list under the field,
///  2. an inline "ghost" completion of the best prefix match, accepted with a tap,
///  3. a "did you mean" nudge when what you typed is one typo away from an existing dish.
struct DishNameField: View {
    @Binding var text: String
    /// The existing dish this entry will attach to, if any.
    @Binding var linkedDishID: UUID?

    let dishes: [Dish]
    let history: [UUID: DishHistory]
    var favoriteIDs: Set<UUID> = []

    @FocusState private var focused: Bool

    private var linkedDish: Dish? {
        linkedDishID.flatMap { id in dishes.first { $0.id == id } }
    }

    private var suggestions: [DishRepository.NameSuggestion] {
        guard focused else { return [] }
        let all = DishRepository.suggestions(for: text, in: dishes, history: history, favoriteIDs: favoriteIDs)
        // Don't offer what's already typed verbatim.
        return all.filter { $0.name.normalizedForMatching != text.normalizedForMatching }
    }

    /// The completion we can offer inline: a dish that starts with what's typed.
    private var ghostCompletion: String? {
        let typed = text
        guard !typed.isEmpty, focused else { return nil }
        let key = typed.normalizedForMatching
        guard !key.isEmpty else { return nil }
        guard let match = suggestions.first(where: { $0.name.normalizedForMatching.hasPrefix(key) }) else { return nil }
        guard match.name.count > typed.count else { return nil }
        // Only safe to append when the visible text is a real prefix of the match.
        guard match.name.lowercased().hasPrefix(typed.lowercased()) else { return nil }
        return String(match.name.dropFirst(typed.count))
    }

    private var typoCandidate: Dish? {
        guard !text.isEmpty else { return nil }
        guard linkedDishID == nil else { return nil }
        return DishRepository.nearMatch(for: text, in: dishes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s1_5) {
                Input(
                    "What did you cook?",
                    text: $text,
                    ghostText: ghostCompletion,
                    isFocused: $focused
                )
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onChange(of: text) { _, newValue in
                    // Typing something that no longer matches the linked dish unlinks it.
                    if let linkedDish, linkedDish.normalizedName != newValue.normalizedForMatching {
                        linkedDishID = nil
                    }
                }

                if ghostCompletion != nil {
                    AppButton(
                        icon: "arrow.right.to.line.compact",
                        accessibilityLabel: "Accept suggested name",
                        variant: .secondary,
                        appearance: .ghost,
                        action: acceptGhost
                    )
                }

                if linkedDishID != nil {
                    Image(systemName: "link")
                        .textStyle(.sansSm, tone: .accent)
                        .accessibilityLabel("Linked to an existing dish")
                }
            }

            if let linkedDish {
                let served = history[linkedDish.id]?.timesServed ?? 0
                Text("Same dish as \(served) earlier \(served == 1 ? "entry" : "entries").")
                    .textStyle(.sansSm, tone: .tertiary)
            }

            if let typoCandidate {
                HStack(spacing: DS.Spacing.s2) {
                    Text("Did you mean **\(typoCandidate.name)**?")
                        .textStyle(.sansSm, tone: .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    AppButton("Use it", variant: .secondary, appearance: .soft, size: .xs) {
                        apply(name: typoCandidate.name, dishID: typoCandidate.id)
                    }
                }
            }

            if !suggestions.isEmpty {
                Card(layout: .list) {
                    ForEach(suggestions) { suggestion in
                        ListRow(suggestion.name, value: subtitle(for: suggestion), chevron: false, size: .sm) {
                            if let dish = dishes.first(where: { $0.id == suggestion.dishID }) {
                                apply(name: dish.name, dishID: dish.id)
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(DS.Motion.layout, value: suggestions.map(\.id))
    }

    private func subtitle(for suggestion: DishRepository.NameSuggestion) -> String {
        var parts: [String] = []
        if suggestion.timesServed > 0 {
            parts.append("\(suggestion.timesServed)×")
        }
        if let last = suggestion.lastServed {
            let days = Int(Date.now.timeIntervalSince(last) / 86_400)
            parts.append(days <= 0 ? "today" : "\(days)d ago")
        }
        return parts.joined(separator: " · ")
    }

    private func acceptGhost() {
        guard let ghost = ghostCompletion else { return }
        let completed = text + ghost
        let dish = dishes.first { $0.normalizedName == completed.normalizedForMatching }
        apply(name: dish?.name ?? completed, dishID: dish?.id)
    }

    private func apply(name: String, dishID: UUID?) {
        text = name
        linkedDishID = dishID
        focused = false
    }
}
