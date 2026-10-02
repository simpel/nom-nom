import SwiftUI

/// The multi-line text field: Input's one style, radius, side padding, text step and
/// states, growing from 3 to 6 lines by default. Top padding `s2_5` puts the first line
/// where an Input's text sits; never shorter than an Input.
///
/// `maxLength` adds a live `{n} / {max}` counter under the field. Going over is an
/// error state, not a hard stop: the person keeps typing and keeps their words.
struct TextArea: View {
    var placeholder: String
    var label: String?
    @Binding var text: String
    var lineLimit: ClosedRange<Int>
    var appearance: InputAppearance
    var maxLength: Int?
    var hint: String?
    var error: String?
    var isError: Bool
    var readOnly: Bool
    var disabled: Bool
    var externalFocus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    init(
        _ placeholder: String = "",
        label: String? = nil,
        text: Binding<String>,
        lineLimit: ClosedRange<Int> = 3...6,
        appearance: InputAppearance = .soft,
        maxLength: Int? = nil,
        hint: String? = nil,
        error: String? = nil,
        isError: Bool = false,
        readOnly: Bool = false,
        disabled: Bool = false,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.placeholder = placeholder
        self.label = label
        self._text = text
        self.lineLimit = lineLimit
        self.appearance = appearance
        self.maxLength = maxLength
        self.hint = hint
        self.error = error
        self.isError = isError
        self.readOnly = readOnly
        self.disabled = disabled
        self.externalFocus = isFocused
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }
    private var isPlain: Bool { appearance == .plain }
    private var isOver: Bool { maxLength.map { text.count > $0 } ?? false }
    private var isInvalid: Bool { isError || isOver || !(error ?? "").isEmpty }
    private var state: InputState {
        InputState(focused: isFocused, error: isInvalid, readOnly: readOnly, disabled: disabled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: InputMetrics.messageSpacing) {
            fieldBox
            InputMessage(hint: hint, error: error, isError: isError, count: text.count, maxLength: maxLength)
        }
        .animation(InputMetrics.animation, value: error)
        .announcesInputError(error)
    }

    private var fieldBox: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
            if let label, !label.isEmpty {
                Text(label)
                    .textStyle(.sansXs, tone: nil)
                    .foregroundStyle(InputMetrics.label(state))
                    .lineLimit(1)
            }
            editor
                .textStyle(.sansMd, tone: nil)
                .foregroundStyle(InputMetrics.text(state))
                .lineLimit(lineLimit)
                .disabled(disabled)
        }
        .frame(maxWidth: .infinity, minHeight: InputMetrics.height, alignment: .topLeading)
        .padding(.horizontal, isPlain ? 0 : InputMetrics.sidePadding)
        .padding(.vertical, isPlain ? 0 : InputMetrics.textAreaTopPadding)
        .modifier(InputChrome(appearance: appearance, state: state))
    }

    @ViewBuilder
    private var editor: some View {
        if readOnly {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .accessibilityLabel(label ?? placeholder)
                .accessibilityValue(text)
        } else {
            let field = TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(DS.Color.textTertiary),
                axis: .vertical
            )
            .accessibilityLabel(label ?? placeholder)
            .accessibilityHint(error ?? hint ?? "")
            if let externalFocus {
                field.focused(externalFocus)
            } else {
                field.focused($internalFocus)
            }
        }
    }
}
