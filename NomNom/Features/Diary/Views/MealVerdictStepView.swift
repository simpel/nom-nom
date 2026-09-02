import SwiftUI

/// Step 2 of logging a meal: A rich hero moment to evaluate your personal Taste verdict and Rotation goal.
struct MealVerdictStepView: View {
    let draft: FoodStore.MealDraft
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var myReaction: Reaction?
    @State private var repeatDesire: RotationGoal?
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Hero Section: Arced Photo Deck (if photos exist)
                if !draft.photos.isEmpty {
                    RecipePhotoArcDeck(draft: draft.photos)
                }

                // Centered Dish Title & Date
                PageHeader(
                    title: draft.dishName,
                    subtitle: draft.eatenOn.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
                )

                // Axis 1: Taste Verdict (3-card selector)
                tasteSectionCard

                // Axis 2: Rotation Goal (3-card selector)
                rotationSectionCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .screenTitle("Rate Meal")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            myReaction = draft.verdicts[.account(store.userID)]
            repeatDesire = draft.repeatDesire
        }
        .interactiveDismissDisabled(isSaving)
        .alert("Couldn't save meal",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: - Taste Section

    private var tasteSectionCard: some View {
        SectionCard(
            title: "How was it?",
            caption: myReaction?.name,
            color: myReaction?.tint
        ) {
            TactileOptionPicker(selection: $myReaction)
        }
    }

    // MARK: - Rotation Section

    private var rotationSectionCard: some View {
        SectionCard(
            title: "How often to repeat",
            caption: repeatDesire?.title,
            color: repeatDesire?.tint
        ) {
            TactileOptionPicker(selection: $repeatDesire)
        }
    }

    private func save() {
        var finalDraft = draft
        var updatedVerdicts = draft.verdicts
        let myRef: RaterRef = .account(store.userID)
        if let reaction = myReaction {
            updatedVerdicts[myRef] = reaction
        } else {
            updatedVerdicts.removeValue(forKey: myRef)
        }
        finalDraft.verdicts = updatedVerdicts
        finalDraft.repeatDesire = repeatDesire

        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let ok = await store.save(finalDraft)
            isSaving = false
            if ok {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss()
            }
        }
    }
}
