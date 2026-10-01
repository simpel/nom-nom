import SwiftUI

/// Editable row for a local eater (no account). The avatar is the eater's initials.
struct EaterRow: View {
    let eater: Eater

    @Environment(FoodStore.self) private var store
    @State private var name: String

    init(eater: Eater) {
        self.eater = eater
        self._name = State(initialValue: eater.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            UserAvatar(name: name.trimmedName.isEmpty ? eater.name : name, size: 34)

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
