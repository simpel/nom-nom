import SwiftUI

/// A screen section: an inset SectionHeader (`s2` above the content, lined up
/// with the card corners below) above any content. Named `DSSection` because
/// `Section` would shadow `SwiftUI.Section`. Sections stack `s7` apart on a
/// detail screen (`DS.Spacing.block`).
struct DSSection<Content: View>: View {
    let title: String
    var trailing: String?
    var trailingTone: SectionHeaderTrailingTone
    var systemImage: String?
    var uppercase: Bool
    @ViewBuilder var content: Content

    init(
        _ title: String,
        trailing: String? = nil,
        trailingTone: SectionHeaderTrailingTone = .secondary,
        systemImage: String? = nil,
        uppercase: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailing = trailing
        self.trailingTone = trailingTone
        self.systemImage = systemImage
        self.uppercase = uppercase
        self.content = content()
    }

    var body: some View {
        // The inset SectionHeader carries the `s2` gap below itself.
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title,
                trailing: trailing,
                trailingTone: trailingTone,
                systemImage: systemImage,
                uppercase: uppercase,
                inset: true
            )
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DSSectionGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            DSSection("Who rated", trailing: "5 of 6") {
                Card(layout: .list) {
                    Text("Anna").textStyle(.sansMd).frame(minHeight: DS.Spacing.rowMin)
                    Text("Joel").textStyle(.sansMd).frame(minHeight: DS.Spacing.rowMin)
                }
            }
            DSSection("This recipe over time", trailing: "3 times", trailingTone: .primary) {
                Card { Text("Timeline").textStyle(.sansMd) }
            }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { DSSectionGallery() }
#Preview("Dark") { DSSectionGallery().preferredColorScheme(.dark) }
