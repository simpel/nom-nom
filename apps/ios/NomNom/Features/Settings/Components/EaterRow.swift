import SwiftUI

/// Editable row for a local eater (no account): a ListRow with the eater's initials as
/// Avatar `sm` and the name as a `plain` Input (Input README: `plain` only inside a
/// Card list row). Saves on return. Place it in `Card(layout: .list)`.
struct EaterRow: View {
    let eater: Eater

    @Environment(FoodStore.self) private var store
    @State private var name: String

    init(eater: Eater) {
        self.eater = eater
        self._name = State(initialValue: eater.name)
    }

    var body: some View {
        ListRow(
            accessibilityTitle: eater.name,
            leading: .avatar(Avatar(name: name.trimmedName.isEmpty ? eater.name : name, size: .sm, decorative: true))
        ) {
            Input("Name", text: $name, appearance: .plain)
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
