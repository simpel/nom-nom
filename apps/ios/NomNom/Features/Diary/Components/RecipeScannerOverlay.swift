import SwiftUI

/// Loading and progress overlay displayed while AI analyzes recipe photos.
struct RecipeScannerOverlay: View {
    var onCancel: () -> Void

    @State private var phaseIndex = 0
    private let timer = Timer.publish(every: 2.2, on: .main, in: .common).autoconnect()

    private let statusPhases = [
        "Reading text & layout from photos...",
        "Extracting ingredients & measurements...",
        "Structuring cooking instructions & steps...",
        "Finalizing recipe details..."
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(DS.Color.accent)

                VStack(spacing: 8) {
                    Text("Analyzing Recipe")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(currentStatus)
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: phaseIndex)
                }

                AppButton(
                    "Cancel",
                    variant: .neutral,
                    style: .ghost,
                    size: .sm
                ) {
                    onCancel()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 280)
            .background(DS.Color.panel)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 24, y: 8)
            .onReceive(timer) { _ in
                if phaseIndex < statusPhases.count - 1 {
                    phaseIndex += 1
                }
            }
        }
    }

    private var currentStatus: String {
        statusPhases[min(phaseIndex, statusPhases.count - 1)]
    }
}
