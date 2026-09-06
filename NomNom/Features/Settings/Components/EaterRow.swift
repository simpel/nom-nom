import SwiftUI

/// Editable row for a local eater (no account).
struct EaterRow: View {
    let eater: Eater
    let emojiChoices: [String]

    @Environment(FoodStore.self) private var store
    @State private var name: String

    init(eater: Eater, emojiChoices: [String]) {
        self.eater = eater
        self.emojiChoices = emojiChoices
        self._name = State(initialValue: eater.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(emojiChoices, id: \.self) { emoji in
                    Button(emoji) { commit { $0.emoji = emoji } }
                }
            } label: {
                Text(eater.emoji).font(.title2)
            }

            Input("Name", text: $name, size: .sm, style: .plain)
                .onSubmit { commit { $0.name = name } }
        }
        .onChange(of: eater.name) { _, updated in
            if updated != name { name = updated }
        }
    }

    private func commit(_ change: (inout Eater) -> Void) {
        var updated = eater
        updated.name = name.trimmedName.isEmpty ? eater.name : name.trimmedName
        change(&updated)
        Task { await store.update(eater: updated) }
    }
}
