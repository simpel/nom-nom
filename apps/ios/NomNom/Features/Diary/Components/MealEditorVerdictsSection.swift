import SwiftUI

/// Member and household verdicts for the meal editor: a Card with each rater's name
/// over a TasteScoreSelector, a link to add household members, and a note on blanks.
struct MealEditorVerdictsSection: View {
    @Binding var verdicts: [RaterRef: Reaction]
    @Environment(FoodStore.self) private var store

    var body: some View {
        DSSection("How was it?") {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                Card(spacing: DS.Spacing.s5) {
                    ForEach(store.raterRoster, id: \.ref) { person in
                        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                            Text(person.name).textStyle(.sansMd, weight: .semibold)
                            TasteScoreSelector(selection: binding(for: person.ref), label: person.name)
                        }
                    }
                }

                if store.activeEaters.isEmpty {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        AppButtonLabel(
                            "Add household members to rate per person",
                            variant: .secondary,
                            appearance: .ghost,
                            size: .sm
                        )
                    }
                    .buttonStyle(AppPressableButtonStyle())
                }

                Text("Leave blank if you didn't catch a reaction — blanks are ignored by the suggestions instead of counting as a bad score.")
                    .textStyle(.sansSm, tone: .tertiary)
                    .padding(.horizontal, DS.Spacing.sectionInset)
            }
        }
    }

    private func binding(for ref: RaterRef) -> Binding<Reaction?> {
        Binding(
            get: { verdicts[ref] },
            set: { verdicts[ref] = $0 }
        )
    }
}
