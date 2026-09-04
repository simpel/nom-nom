import SwiftUI

/// Step 2 of logging a meal: A rich hero moment to evaluate your personal Taste verdict and Rotation goal.
struct MealVerdictStepView: View {
    let draft: FoodStore.MealDraft
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store
    @State private var myReaction: Reaction?
    @State private var repeatDesire: RotationGoal?
    @State private var isSaving = false
    @State private var selectedPhotoIndex: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                // Top Hero Section: Harmonized Arc Hero Header
                ArcHeroHeaderView(
                    draft: draft.photos,
                    title: draft.dishName.isEmpty ? "Rate Meal" : draft.dishName,
                    date: draft.eatenOn,
                    alignment: .center
                ) { index in
                    selectedPhotoIndex = index
                }
                .padding(.bottom, 4)

                // Axis 1: Taste Verdict (Standalone 6-tile selector)
                tasteSection

                // Axis 2: Rotation Goal (Standalone 3-card selector)
                rotationSection
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .screenTitle("Rate Meal", displayMode: .inline)
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
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndexWrapper(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { wrapper in
            if !draft.photos.isEmpty {
                MealPhotoViewerSheet(draft: draft.photos, initialIndex: wrapper.index)
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

    private var tasteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "How was it?",
                trailingText: myReaction?.name,
                trailingColor: myReaction?.text,
                horizontalPadding: 4
            )
            TasteScoreSelector(selection: $myReaction)
        }
    }

    // MARK: - Rotation Section

    private var rotationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                "How often to repeat",
                trailingText: repeatDesire?.title,
                trailingColor: DS.Color.accentText,
                horizontalPadding: 4
            )
            RotationGoalSelector(selection: $repeatDesire)
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
