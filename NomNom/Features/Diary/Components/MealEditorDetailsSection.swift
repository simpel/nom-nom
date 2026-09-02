import SwiftUI

/// Sections in MealEditorView for date/notes, invite shortcuts, and meal deletion.
struct MealEditorDetailsSection: View {
    @Binding var date: Date
    @Binding var notes: String
    let meal: Meal?
    let isSaving: Bool
    let onDelete: () -> Void

    @Environment(FoodStore.self) private var store

    var body: some View {
        SectionCard("Details") {
            VStack(spacing: 12) {
                DatePicker("When", selection: $date, displayedComponents: [.date])

                Divider()

                TextField("Chef notes / adjustments", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }

        if let meal, meal.createdBy == store.userID {
            SectionCard {
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink {
                        MealInviteView(mealID: meal.id)
                    } label: {
                        let count = store.invites(forMeal: meal.id).count
                        HStack {
                            Label(count == 0 ? "Ask someone to rate this"
                                             : "Invited \(count) \(count == 1 ? "person" : "people")",
                                  systemImage: "person.badge.plus")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("They'll get this meal on their Meals page and can leave their own rating.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if meal != nil {
            SectionCard {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete this meal", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
        }
    }
}
