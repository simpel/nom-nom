import SwiftUI

/// The meal or recipe's kitchens: a pressable SectionCard that opens the cuisine
/// picker. Chosen cuisines are `sm` Badges.
struct CuisinePickerSection: View {
    @Binding var selection: String?

    @State private var showingSheet = false

    private var selectedItems: [String] {
        Cuisine.parseMultiple(from: selection)
    }

    var body: some View {
        SectionCard(
            "Kitchen / Cuisine",
            trailing: selectedItems.isEmpty ? nil : "\(selectedItems.count) selected",
            action: { showingSheet = true }
        ) {
            if selectedItems.isEmpty {
                Text("Choose kitchen / cuisines\u{2026}").textStyle(.sansMd, tone: .secondary)
            } else {
                // bundle.css `.nn-detail-header__badges`: a run of Badges `spacing-1.5` apart.
                WrappingHStack(spacing: DS.Spacing.s1_5, lineSpacing: DS.Spacing.s1_5) {
                    ForEach(selectedItems, id: \.self) { item in
                        Badge(Cuisine.matching(from: item)?.displayName ?? item.capitalized, size: .sm)
                    }
                }
            }
        }
        .accessibilityLabel(
            selectedItems.isEmpty
                ? "Select kitchen or cuisine"
                : "Cuisines: \(selectedItems.joined(separator: ", ")). Tap to edit."
        )
        .sheet(isPresented: $showingSheet) {
            CuisinePickerSheet(selection: $selection)
        }
    }
}

#Preview {
    NomNomPreview {
        VStack(spacing: DS.Spacing.s4) {
            CuisinePickerSection(selection: .constant(nil))
            CuisinePickerSection(selection: .constant("italian, mexican"))
        }
        .padding(DS.Spacing.gutter)
    }
}
