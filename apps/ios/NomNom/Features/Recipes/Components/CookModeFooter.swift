import SwiftUI

/// Cook mode's bottom actions: Back (secondary soft, disabled on the first step) and
/// Next (primary solid) side by side, both `lg`; on the last step "Log this meal" (plus,
/// solid) over "Back to step N" (secondary ghost).
struct CookModeFooter: View {
    let index: Int
    let isLast: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onLogMeal: () -> Void

    var body: some View {
        Group {
            if isLast {
                VStack(spacing: DS.Spacing.s2) {
                    AppButton("Log this meal", icon: "plus", size: .lg, fullWidth: true, action: onLogMeal)
                    if index > 0 {
                        AppButton("Back to step \(index)", variant: .secondary, appearance: .ghost, size: .lg, fullWidth: true, action: onBack)
                    }
                }
            } else {
                HStack(spacing: DS.Spacing.s2) {
                    AppButton("Back", variant: .secondary, appearance: .soft, size: .lg, fullWidth: true, action: onBack)
                        .disabled(index == 0)
                    AppButton("Next", size: .lg, fullWidth: true, action: onNext)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.gutter)
        .padding(.top, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s4)
    }
}
