import SwiftUI

/// Two-column ingredients table (amount, ingredient) in a SectionCard. Tapping a row
/// checks it off (struck through, `text-tertiary`) for the cook.
struct RecipeIngredientsCard: View {
    let ingredients: [RecipeIngredient]

    @State private var completedIDs: Set<UUID> = []

    private var validIngredients: [RecipeIngredient] {
        ingredients.filter { !$0.isEmpty }
    }

    private let amountColumnWidth = DS.Spacing.s20

    var body: some View {
        if !validIngredients.isEmpty {
            SectionCard("Ingredients", trailing: "\(validIngredients.count) items") {
                VStack(spacing: 0) {
                    HStack(spacing: DS.Spacing.s3) {
                        SectionHeader("Amount", inset: false)
                            .frame(width: amountColumnWidth, alignment: .trailing)
                        SectionHeader("Ingredient", inset: false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, DS.Spacing.s2)

                    ForEach(validIngredients) { item in
                        hairline
                        ingredientRow(for: item)
                    }
                }
            }
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(DS.Color.line)
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private func ingredientRow(for item: RecipeIngredient) -> some View {
        let isCompleted = completedIDs.contains(item.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isCompleted {
                    completedIDs.remove(item.id)
                } else {
                    completedIDs.insert(item.id)
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s3) {
                Text(item.formattedAmount)
                    .strikethrough(isCompleted, color: DS.Color.textTertiary)
                    .textStyle(.sansSm, tone: isCompleted ? .tertiary : .accent, weight: .semibold, numeric: true)
                    .frame(width: amountColumnWidth, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(item.trimmedIngredient)
                    .strikethrough(isCompleted, color: DS.Color.textTertiary)
                    .textStyle(.sansSm, tone: isCompleted ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, DS.Spacing.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }
}
