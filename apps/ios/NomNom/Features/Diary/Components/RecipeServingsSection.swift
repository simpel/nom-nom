import SwiftUI

/// The number of servings a recipe makes: a SectionCard named "Servings" with a
/// ValueStepper (the numeral alone, since the card's title already names it).
/// An unset recipe reads the stepper's minimum until it is changed.
struct RecipeServingsSection: View {
    @Binding var serves: Int?

    private static let range = 1...30

    private var value: Binding<Int> {
        Binding(get: { serves ?? Self.range.lowerBound }, set: { serves = $0 })
    }

    var body: some View {
        SectionCard("Servings") {
            HStack(spacing: DS.Spacing.s3) {
                Text(serves == nil ? "Not set yet" : "Portions the recipe makes")
                    .textStyle(.sansSm, tone: .tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ValueStepper(value: value, in: Self.range, label: "Servings")
            }
        }
    }
}

#Preview {
    RecipeServingsSection(serves: .constant(4))
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
}
