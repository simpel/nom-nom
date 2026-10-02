import SwiftUI

/// Onboarding progress in the navigation bar: a single-fill Bar `xs` reading
/// "step N of total" (Bar README: "One fill means one quantity"). The DS gives a bar
/// no width of its own; in the bar's principal slot it takes `spacing-20`
/// (DS-GAPS.md, "shell").
struct OnboardingStepProgress: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        Bar(
            value: Double(currentStep + 1),
            max: Double(totalSteps),
            size: .xs,
            label: "Step \(currentStep + 1) of \(totalSteps)"
        )
        .frame(width: DS.Spacing.s20)
    }
}
