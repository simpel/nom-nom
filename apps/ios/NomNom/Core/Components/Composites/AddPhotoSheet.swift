import SwiftUI

/// What the person picked in the Add photo sheet.
enum AddPhotoChoice {
    case generate, camera, library
}

/// The small sheet a photo strip's add tile opens: "Generate with AI" first, as a
/// ProLinkCard so it reads as the Pro option, then a Card list of "Take photo" (when
/// there is a camera) and "Choose from library". It opens just tall enough for its
/// content and closes on a choice; `.addPhotoSheet` runs the choice once it has closed.
struct AddPhotoSheet: View {
    var offersGenerate: Bool
    let onChoose: (AddPhotoChoice) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0
    @State private var insets: CGFloat = 0
    @State private var detent: PresentationDetent = .medium

    /// SheetBody's `spacing-2` top and `spacing-10` bottom padding around the blocks.
    private var fitDetent: PresentationDetent {
        guard contentHeight > 0 else { return .medium }
        return .height(insets + DS.Spacing.s2 + contentHeight + DS.Spacing.s10)
    }

    var body: some View {
        NavigationStack {
            SheetBody {
                VStack(spacing: DS.Spacing.s4) {
                    if offersGenerate {
                        Button { choose(.generate) } label: {
                            ProLinkCard(title: "Generate with AI", subtitle: "A photo plated from the name and ingredients")
                        }
                        .buttonStyle(AppPressableButtonStyle())
                    }
                    Card(layout: .list) {
                        if CameraPicker.isAvailable {
                            ListRow("Take photo") { choose(.camera) }
                        }
                        ListRow("Choose from library") { choose(.library) }
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } action: { insets = $0 }
            .screenTitle("Add photo", displayMode: .inline)
            .sheetCancelToolbar()
        }
        .dsSheet(detents: [fitDetent], selection: $detent)
        .onChange(of: fitDetent) { _, new in detent = new }
    }

    private func choose(_ choice: AddPhotoChoice) {
        onChoose(choice)
        dismiss()
    }
}

#Preview("Light") {
    NomNomPreview(inNavigationStack: false) { _ in
        Color.clear.sheet(isPresented: .constant(true)) {
            AddPhotoSheet(offersGenerate: true) { _ in }
        }
    }
}
