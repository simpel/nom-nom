import SwiftUI

/// The multi-line text field: Input's radius, side padding, text step and states,
/// growing from 3 to 6 lines by default. Top padding `s2_5` puts the first line
/// where an Input's text sits; never shorter than an Input.
struct TextArea: View {
    var placeholder: String
    var label: String?
    @Binding var text: String
    var lineLimit: ClosedRange<Int>
    var appearance: InputAppearance
    var isError: Bool
    var disabled: Bool
    var externalFocus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    init(
        _ placeholder: String = "",
        label: String? = nil,
        text: Binding<String>,
        lineLimit: ClosedRange<Int> = 3...6,
        appearance: InputAppearance = .soft,
        isError: Bool = false,
        disabled: Bool = false,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.placeholder = placeholder
        self.label = label
        self._text = text
        self.lineLimit = lineLimit
        self.appearance = appearance
        self.isError = isError
        self.disabled = disabled
        self.externalFocus = isFocused
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }
    private var isPlain: Bool { appearance == .plain }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label, !label.isEmpty {
                Text(label)
                    .textStyle(.sansXs, tone: nil)
                    .foregroundStyle(isFocused ? DS.Color.primaryText : DS.Color.textSecondary)
                    .lineLimit(1)
            }
            editor
                .textStyle(.sansMd, tone: nil)
                .foregroundStyle(disabled ? DS.Color.textTertiary : DS.Color.textPrimary)
                .lineLimit(lineLimit)
                .disabled(disabled)
        }
        .frame(maxWidth: .infinity, minHeight: InputMetrics.height, alignment: .topLeading)
        .padding(.horizontal, isPlain ? 0 : InputMetrics.sidePadding)
        .padding(.vertical, isPlain ? 0 : DS.Spacing.s2_5)
        .background(InputMetrics.background(appearance), in: InputMetrics.shape)
        .overlay {
            if let border = InputMetrics.border(appearance, focused: isFocused, error: isError) {
                InputMetrics.shape.strokeBorder(
                    border,
                    lineWidth: InputMetrics.borderWidth(focused: isFocused, error: isError)
                )
            }
        }
        .contentShape(InputMetrics.shape)
        .animation(InputMetrics.animation, value: isFocused)
        .animation(InputMetrics.animation, value: isError)
        .opacity(disabled ? DS.Opacity.disabled : DS.Opacity.o100)
    }

    @ViewBuilder
    private var editor: some View {
        let field = TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundStyle(DS.Color.textTertiary),
            axis: .vertical
        )
        if let externalFocus {
            field.focused(externalFocus)
        } else {
            field.focused($internalFocus)
        }
    }
}

private struct TextAreaGallery: View {
    @State private var empty = ""
    @State private var notes = "Made extra crispy with homemade salsa verde."

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            TextArea("Describe your dinner party\u{2026}", text: $empty)
            TextArea("Add any adjustments\u{2026}", label: "Notes", text: $notes)
            TextArea("Outline", text: $empty, appearance: .outline)
            TextArea("Error", text: $notes, isError: true)
            TextArea("Disabled", text: $notes, disabled: true)
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { TextAreaGallery() }
#Preview("Dark") { TextAreaGallery().preferredColorScheme(.dark) }
