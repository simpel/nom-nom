import SwiftUI
import Combine

/// Loading and progress overlay displayed while AI analyzes recipe photos: a `scrim`
/// over the sheet and a floating Card (`shadow-lg`, README: "`shadow-lg` for popovers")
/// with a spinner, the current phase and a Cancel button.
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
            DS.Color.scrim
                .ignoresSafeArea()

            Card(spacing: DS.Spacing.s4) {
                VStack(spacing: DS.Spacing.s4) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(DS.Color.primary)

                    VStack(spacing: DS.Spacing.s2) {
                        Text("Analyzing Recipe")
                            .textStyle(.sansLg, weight: .semibold, align: .center)

                        Text(currentStatus)
                            .textStyle(.sansMd, tone: .secondary, align: .center)
                            .animation(DS.Motion.layout, value: phaseIndex)
                    }

                    AppButton("Cancel", variant: .secondary, appearance: .ghost, size: .sm) {
                        onCancel()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: DS.Spacing.s72)
            .dsShadow(.lg, cornerRadius: DS.Radius.xl3)
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
