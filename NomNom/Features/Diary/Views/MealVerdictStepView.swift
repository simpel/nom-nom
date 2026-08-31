import SwiftUI

/// Step 2 of logging a meal: record your own verdict (and any household members) before saving.
struct MealVerdictStepView: View {
    let draft: FoodStore.MealDraft
    let pickedData: Data?
    let existingPath: String?
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var verdicts: [RaterRef: Reaction] = [:]
    @State private var isSaving = false

    var body: some View {
        Form {
            mealSummaryHeader

            Section {
                ForEach(store.raterRoster, id: \.ref) { person in
                    ReactionPicker(emoji: person.emoji,
                                   name: person.name,
                                   selection: binding(for: person.ref))
                }
            } header: {
                Text("How was it?")
            } footer: {
                Text("Leave blank if you didn't catch a reaction — blanks are ignored by the suggestions.")
            }
        }
        .navigationTitle("Rate meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            verdicts = draft.verdicts
        }
        .interactiveDismissDisabled(isSaving)
    }

    private var mealSummaryHeader: some View {
        Section {
            HStack(spacing: 14) {
                if let pickedData, let uiImage = UIImage(data: pickedData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else if let existingPath {
                    RemoteMealPhoto(path: existingPath, cornerRadius: 10)
                        .frame(width: 56, height: 56)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 56, height: 56)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.dishName)
                        .font(.headline)
                    Text(draft.eatenOn, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func binding(for ref: RaterRef) -> Binding<Reaction?> {
        Binding(
            get: { verdicts[ref] },
            set: { verdicts[ref] = $0 }
        )
    }

    private func save() {
        var finalDraft = draft
        finalDraft.verdicts = verdicts
        isSaving = true
        Task {
            let ok = await store.save(finalDraft)
            isSaving = false
            if ok {
                onDismiss()
            }
        }
    }
}
