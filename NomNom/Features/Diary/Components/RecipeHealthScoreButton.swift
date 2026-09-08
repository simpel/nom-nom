import SwiftUI

/// Compact interactive health score badge matching the visual design of the average rating card:
/// - Fine hairline vertical divider between numerical score and qualitative verdict
/// - Sits side-by-side with the primary "Use in Meal" action
/// - Tapping presents the detailed health rationale or triggers on-demand analysis
struct RecipeHealthScoreButton: View {
    let recipe: Recipe

    @Environment(FoodStore.self) private var store
    @State private var showingRationale = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private var healthIndex: HealthIndex? {
        recipe.healthIndex
    }

    var body: some View {
        Group {
            if let health = healthIndex {
                Button {
                    showingRationale = true
                } label: {
                    HStack(spacing: 0) {
                        // Numerical score
                        Text("\(health.score)")
                            .font(Font.newsreader(.title3, weight: .semibold))
                            .foregroundStyle(health.scoreColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        // Fine hairline divider
                        Rectangle()
                            .fill(DS.Color.line.opacity(0.4))
                            .frame(width: 1, height: 22)

                        // Qualitative verdict
                        Text(health.verdict)
                            .font(Font.newsreader(.subheadline, weight: .semibold))
                            .foregroundStyle(health.scoreColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(height: AppButtonSize.md.height)
                    .padding(.horizontal, 10)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .fill(DS.Color.panel)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                    .strokeBorder(DS.Color.line.opacity(0.35), lineWidth: 0.5)
                            }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }
                .buttonStyle(AppPressableButtonStyle())
            } else {
                AppButton(
                    "Analyze Health",
                    icon: .system("sparkles"),
                    variant: .secondary,
                    style: .outlined,
                    size: .md,
                    isFullWidth: true,
                    isPending: isAnalyzing
                ) {
                    analyzeHealth()
                }
            }
        }
        .accessibilityLabel(accessibilityDescription)
        .sheet(isPresented: $showingRationale) {
            if let health = healthIndex {
                RecipeHealthRationaleSheet(recipe: recipe, healthIndex: health)
            }
        }
        .alert("Health Analysis Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Could not calculate recipe health index. Please try again.")
        }
    }

    private var accessibilityDescription: String {
        if let health = healthIndex {
            return "Health index: \(health.score) out of 100, \(health.verdict). Tap to view rationale."
        } else {
            return "Recipe health index uncalculated. Tap to analyze."
        }
    }

    private func analyzeHealth() {
        Task {
            isAnalyzing = true
            do {
                _ = try await store.analyzeHealth(for: recipe)
                isAnalyzing = false
                showingRationale = true
            } catch {
                isAnalyzing = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}
