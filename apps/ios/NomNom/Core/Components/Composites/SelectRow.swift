import SwiftUI

/// A row that picks one of a few options (components/SelectRow/README.md): a ListRow
/// whose value is the current choice with a `chevron.up.chevron.down` glyph. Tapping
/// opens the platform's own picker (a Menu), so VoiceOver reads it as a pop-up button.
/// For a choice of 3 to 12 that does not deserve its own screen.
///
/// ```swift
/// Card(layout: .list) {
///     SelectRow("Group", selection: $groupID, options: groups.map { .init($0.id, $0.name) })
/// }
/// ```
struct SelectRow<Value: Hashable>: View {
    let title: String
    var meta: String?
    @Binding var selection: Value
    let options: [SelectRowOption<Value>]

    init(_ title: String, meta: String? = nil, selection: Binding<Value>, options: [SelectRowOption<Value>]) {
        self.title = title
        self.meta = meta
        self._selection = selection
        self.options = options
    }

    private var selectedLabel: String {
        options.first { $0.value == selection }?.label ?? ""
    }

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options) { Text($0.label).tag($0.value) }
            }
        } label: {
            // bundle.js SelectRow: the title semibold, the choice `sans-sm` secondary,
            // then the `chevron-up-down` glyph where a row's chevron sits.
            ListRow(accessibilityTitle: title, meta: meta, trailing: .view {
                HStack(spacing: DS.Spacing.s2) {
                    Text(selectedLabel).textStyle(.sansSm, tone: .secondary, lines: 1)
                    Image(systemName: "chevron.up.chevron.down")
                        .textStyle(.sansMd, tone: .tertiary)
                        .accessibilityHidden(true)
                }
            }, chevron: false) {
                Text(title).textStyle(.sansMd, weight: .semibold)
            }
        }
        .buttonStyle(ListRowButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(selectedLabel)
    }
}

/// One choice in a SelectRow: the value it sets and the label it shows.
struct SelectRowOption<Value: Hashable>: Identifiable {
    let value: Value
    let label: String
    var id: Value { value }

    init(_ value: Value, _ label: String) {
        self.value = value
        self.label = label
    }
}
