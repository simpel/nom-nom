import SwiftUI

/// A screen section: a SectionHeader above any content — the rail of a Timeline,
/// the card of a RatingList, a Card. The header is inset `spacing-2` (so it lines up
/// with the card corners below) and sits `spacing-2` above the content. Sections
/// stack `spacing-7` apart on a detail screen (`DS.Spacing.block`).
///
/// Named `DSSection` because `Section` would shadow `SwiftUI.Section`.
///
/// ```swift
/// DSSection("Ingredients", trailing: "6 items") {
///     Card(layout: .list) { … }
/// }
/// ```
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
        // bundle.css `.nn-section__head`: padding 0 `spacing-2`, margin-bottom `spacing-2`.
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            SectionHeader(
                title: title,
                trailing: trailing,
                trailingTone: trailingTone,
                systemImage: systemImage,
                uppercase: uppercase
            )
            .padding(.horizontal, DS.Spacing.sectionInset)
            // `.nn-section` is a column with no gap of its own.
            VStack(alignment: .leading, spacing: 0) { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DSSectionGallery: View {
    var body: some View {
        VStack(spacing: DS.Spacing.block) {
            DSSection("Who rated", trailing: "5 of 6", trailingTone: .primary) {
                Card(layout: .list) {
                    ListRow("Anna")
                    ListRow("Joel")
                }
            }
            DSSection("This recipe over time", trailing: "3 times") {
                Card { Text("Timeline").textStyle(.sansMd) }
            }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { DSSectionGallery() }
#Preview("Dark") { DSSectionGallery().preferredColorScheme(.dark) }
