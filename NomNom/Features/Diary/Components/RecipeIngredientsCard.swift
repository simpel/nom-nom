import SwiftUI

/// 2-column tabular card for displaying recipe measurements and ingredients.
struct RecipeIngredientsCard: View {
    let ingredients: [RecipeIngredient]

    @State private var completedIDs: Set<UUID> = []

    private var validIngredients: [RecipeIngredient] {
        ingredients.filter { !$0.isEmpty }
    }

    private let amountColumnWidth: CGFloat = 84

    var body: some View {
        if !validIngredients.isEmpty {
            SectionCard("Ingredients", caption: "\(validIngredients.count) items") {
                VStack(spacing: 0) {
                    // Column Headers
                    HStack(spacing: 14) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(width: amountColumnWidth, alignment: .trailing)

                        Text("INGREDIENT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 8)

                    Divider().overlay(DS.Color.line.opacity(0.35))

                    // 2-Column Rows
                    ForEach(Array(validIngredients.enumerated()), id: \.element.id) { index, item in
                        ingredientRow(for: item, index: index)
                    }
                }
            }
        }
    }

    private func ingredientRow(for item: RecipeIngredient, index: Int) -> some View {
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
            VStack(spacing: 0) {
                if index > 0 {
                    Divider().overlay(DS.Color.line.opacity(0.2))
                }

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    // Column 1: Amount (Quantity & Measurement)
                    Text(item.formattedAmount)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isCompleted ? DS.Color.textTertiary : DS.Color.accentText)
                        .strikethrough(isCompleted, color: DS.Color.textTertiary)
                        .frame(width: amountColumnWidth, alignment: .trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    // Column 2: Ingredient Name
                    Text(item.trimmedIngredient)
                        .font(.subheadline)
                        .foregroundStyle(isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .strikethrough(isCompleted, color: DS.Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
}
