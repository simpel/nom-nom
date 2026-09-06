import SwiftUI

/// Minimal progress bar showing active progress across onboarding steps.
struct OnboardingStepProgress: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? DS.Color.textPrimary : DS.Color.line)
                    .frame(height: 3)
                    .frame(maxWidth: index == currentStep ? 28 : 12)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xs)
    }
}
