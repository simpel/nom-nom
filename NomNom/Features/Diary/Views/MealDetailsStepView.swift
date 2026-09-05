import SwiftUI

/// Step 2 of logging a meal: Photos, cooking time / effort, and dinner parties.
struct MealDetailsStepView: View {
    @Binding var draft: FoodStore.MealDraft
    var onDismiss: () -> Void

    @Environment(FoodStore.self) private var store

    @State private var navigateToVerdict = false
    @State private var isSaving = false

    private var isEditing: Bool { draft.mealID != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.section) {
                MealPhotosPickerSection(
                    draft: Binding(
                        get: { draft.photos },
                        set: { draft.photos = $0 }
                    )
                )

                MealEditorCookingTimeSection(
                    effort: Binding(
                        get: { draft.effort },
                        set: { draft.effort = $0 }
                    )
                )

                MealEditorPartiesSection(
                    selectedParties: Binding(
                        get: { draft.servedParties ?? [] },
                        set: { draft.servedParties = $0 }
                    )
                )
            }
            .padding(.horizontal, DS.Spacing.screenHorizontal)
            .padding(.top, DS.Spacing.screenTop)
            .padding(.bottom, DS.Spacing.screenBottom)
        }
        .background(DS.Color.bg)
        .screenTitle("Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else if isEditing {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                } else {
                    Button("Next") {
                        navigateToVerdict = true
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToVerdict) {
            MealVerdictStepView(draft: draft, onDismiss: onDismiss)
        }
        .interactiveDismissDisabled(isSaving)
        .presentationDragIndicator(.visible)
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.height > 90 && abs(value.translation.width) < 60 {
                        onDismiss()
                    }
                }
        )
        .alert("Couldn't save meal",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func save() {
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let ok = await store.save(draft)
            isSaving = false
            if ok {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss()
            }
        }
    }
}
