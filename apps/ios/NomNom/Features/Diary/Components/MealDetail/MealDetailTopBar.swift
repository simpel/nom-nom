import SwiftUI

/// The floating controls on a pushed Meal Detail (the navigation bar is hidden so the
/// photos run to the top): an `elevated` icon-only back button and, for the cook, an
/// `elevated` options menu (Edit, Delete meal).
struct MealDetailTopBar: View {
    var canEdit: Bool
    let onBack: () -> Void
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        HStack {
            AppButton(
                icon: "chevron.left",
                accessibilityLabel: "Back",
                variant: .secondary,
                appearance: .elevated,
                action: onBack
            )
            Spacer()
            if canEdit {
                MealDetailOptionsMenu(onEdit: onEdit, onDelete: onDelete) {
                    AppButtonLabel(
                        nil,
                        icon: "ellipsis",
                        variant: .secondary,
                        appearance: .elevated,
                        accessibilityLabel: "Meal options"
                    )
                }
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.s2)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            // Keeps scrolled content from running under the status bar.
            Color.clear
                .frame(height: 0)
                .background(DS.Color.bg.ignoresSafeArea(edges: .top))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// The cook's meal options: Edit and Delete meal (native Menu buttons, AGENTS.md §8B).
struct MealDetailOptionsMenu<Label: View>: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Menu {
            Button(action: onEdit) {
                SwiftUI.Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                SwiftUI.Label("Delete meal", systemImage: "trash")
            }
        } label: {
            label()
        }
        .accessibilityLabel("Meal options")
    }
}
