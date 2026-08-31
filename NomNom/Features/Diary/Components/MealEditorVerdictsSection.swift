import SwiftUI

/// Member and household verdicts section for the meal editor form.
struct MealEditorVerdictsSection: View {
    @Binding var verdicts: [RaterRef: Reaction]
    @Environment(FoodStore.self) private var store

    var body: some View {
        Section {
            ForEach(store.raterRoster, id: \.ref) { person in
                ReactionPicker(emoji: person.emoji,
                               name: person.name,
                               selection: binding(for: person.ref))
            }

            if store.activeEaters.isEmpty {
                NavigationLink {
                    SettingsView()
                } label: {
                    Text("Add household members to rate per person")
                        .font(.caption)
                }
            }
        } header: {
            Text("Verdict")
        } footer: {
            Text("Leave blank if you didn't catch a reaction — blanks are ignored by the suggestions instead of counting as a bad score.")
        }
    }

    private func binding(for ref: RaterRef) -> Binding<Reaction?> {
        Binding(
            get: { verdicts[ref] },
            set: { verdicts[ref] = $0 }
        )
    }
}
