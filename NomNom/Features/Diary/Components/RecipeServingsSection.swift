import SwiftUI

/// Section card for configuring the number of servings / portions a recipe yields.
struct RecipeServingsSection: View {
    @Binding var serves: Int?

    var body: some View {
        SectionCard("Servings") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(servesText)
                        .font(.body.weight(.medium))
                        .foregroundStyle(serves != nil ? DS.Color.textPrimary : DS.Color.textSecondary)

                    Text(serves != nil ? "Portions / servings yielded" : "Tap plus to specify portions")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        decrement()
                    } label: {
                        Image(systemName: "minus")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .foregroundStyle(serves != nil ? DS.Color.textPrimary : DS.Color.textTertiary)
                            .background(DS.Color.sunken)
                            .clipShape(Circle())
                    }
                    .disabled(serves == nil)
                    .buttonStyle(.plain)

                    Text(serves.map(String.init) ?? "—")
                        .font(.body.monospacedDigit().weight(.semibold))
                        .frame(minWidth: 32)
                        .multilineTextAlignment(.center)

                    Button {
                        increment()
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .foregroundStyle(DS.Color.textPrimary)
                            .background(DS.Color.sunken)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var servesText: String {
        guard let serves else { return "Portions unassigned" }
        return serves == 1 ? "1 serving" : "\(serves) servings"
    }

    private func increment() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let current = serves {
            serves = min(current + 1, 30)
        } else {
            serves = 4 // sensible default
        }
    }

    private func decrement() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let current = serves else { return }
        if current <= 1 {
            serves = nil
        } else {
            serves = current - 1
        }
    }
}
