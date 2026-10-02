import SwiftUI

/// The single-line text field: one style (`soft`; `plain` only inside a Card list row),
/// one height (`s11`, `s14` with a label) and one radius (`radius-xl`), with optional
/// icons, a clear button, a hint and an error message.
///
/// The ground never changes; the border carries every state (see `InputMetrics`):
/// rest 1pt `line-control`, focus 2pt `primary`, error 2pt `destructive`, read-only
/// none (text `text-secondary`), disabled 1pt `line` (text `text-tertiary`).
/// `error` replaces `hint`, so the field never grows when it goes wrong.
struct Input: View {
    var label: String?
    var placeholder: String
    @Binding var text: String
    var leadingIcon: AppInputIcon?
    var trailingIcon: AppInputIcon?
    var appearance: InputAppearance
    var clearable: Bool
    var hint: String?
    var error: String?
    var isError: Bool
    var readOnly: Bool
    var disabled: Bool
    var ghostText: String?
    var externalFocus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    init(
        _ placeholder: String = "",
        label: String? = nil,
        text: Binding<String>,
        leadingIcon: AppInputIcon? = nil,
        trailingIcon: AppInputIcon? = nil,
        appearance: InputAppearance = .soft,
        clearable: Bool = false,
        hint: String? = nil,
        error: String? = nil,
        isError: Bool = false,
        readOnly: Bool = false,
        disabled: Bool = false,
        ghostText: String? = nil,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.placeholder = placeholder
        self.label = label
        self._text = text
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.appearance = appearance
        self.clearable = clearable
        self.hint = hint
        self.error = error
        self.isError = isError
        self.readOnly = readOnly
        self.disabled = disabled
        self.ghostText = ghostText
        self.externalFocus = isFocused
    }

    /// A labelled field. `soft` by default like every field (README: "`appearance`
    /// (`soft` default; `plain` only inside a Card list row)"); pass `.plain` in a row.
    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        leadingIcon: AppInputIcon? = nil,
        trailingIcon: AppInputIcon? = nil,
        appearance: InputAppearance = .soft,
        clearable: Bool = false,
        hint: String? = nil,
        error: String? = nil,
        isError: Bool = false,
        readOnly: Bool = false,
        disabled: Bool = false,
        ghostText: String? = nil,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder, label: label, text: text,
            leadingIcon: leadingIcon, trailingIcon: trailingIcon, appearance: appearance,
            clearable: clearable, hint: hint, error: error, isError: isError,
            readOnly: readOnly, disabled: disabled, ghostText: ghostText, isFocused: isFocused
        )
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }
    private var hasLabel: Bool { !(label ?? "").isEmpty }
    private var isInvalid: Bool { isError || !(error ?? "").isEmpty }
    private var state: InputState {
        InputState(focused: isFocused, error: isInvalid, readOnly: readOnly, disabled: disabled)
    }
    private var showsClear: Bool { clearable && !text.isEmpty && !disabled && !readOnly }

    var body: some View {
        VStack(alignment: .leading, spacing: InputMetrics.messageSpacing) {
            fieldRow
            InputMessage(hint: hint, error: error, isError: isError)
        }
        .animation(InputMetrics.animation, value: error)
        .announcesInputError(error)
    }

    private var fieldRow: some View {
        HStack(spacing: DS.Spacing.s2) {
            if let leadingIcon { iconView(leadingIcon, leading: true) }

            VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                if let label, hasLabel {
                    Text(label)
                        .textStyle(.sansXs, tone: nil)
                        .foregroundStyle(InputMetrics.label(state))
                        .lineLimit(1)
                }
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .textStyle(.sansMd, tone: .tertiary)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }
                    if let ghostText, !ghostText.isEmpty, !readOnly {
                        (Text(text).foregroundStyle(.clear) + Text(ghostText).foregroundStyle(DS.Color.textTertiary))
                            .textStyle(.sansMd, tone: nil)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }
                    field
                }
            }

            if showsClear {
                // bundle.css `.nn-field__clear`: `text-tertiary`, pulled `spacing-2` into
                // the side padding.
                AppButton(
                    icon: "xmark",
                    accessibilityLabel: "Clear text",
                    variant: .secondary,
                    appearance: .ghost,
                    iconColor: DS.Color.textTertiary
                ) { text = "" }
                .padding(.trailing, -DS.Spacing.s2)
            }

            if let trailingIcon { iconView(trailingIcon, leading: false) }
        }
        .frame(maxWidth: .infinity)
        .frame(height: hasLabel ? InputMetrics.labeledHeight : InputMetrics.height)
        .padding(.horizontal, appearance == .plain ? 0 : InputMetrics.sidePadding)
        .modifier(InputChrome(appearance: appearance, state: state))
    }

    @ViewBuilder
    private var field: some View {
        if readOnly {
            Text(text)
                .textStyle(.sansMd, tone: nil)
                .foregroundStyle(InputMetrics.text(state))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .accessibilityLabel(label ?? placeholder)
                .accessibilityValue(text)
        } else {
            let base = TextField("", text: $text)
                .textStyle(.sansMd, tone: nil)
                .foregroundStyle(InputMetrics.text(state))
                .disabled(disabled)
                .accessibilityLabel(label ?? placeholder)
                .accessibilityHint(error ?? hint ?? "")
            if let externalFocus {
                base.focused(externalFocus)
            } else {
                base.focused($internalFocus)
            }
        }
    }

    @ViewBuilder
    private func iconView(_ icon: AppInputIcon, leading: Bool) -> some View {
        let side = DS.TextStyle.sansMd.size
        Group {
            switch icon {
            case .system(let name):
                Image(systemName: name).textStyle(.sansMd, tone: nil)
            case .asset(let name):
                Image(name).resizable().scaledToFit().frame(width: side, height: side)
            case .image(let image):
                image.resizable().scaledToFit().frame(width: side, height: side)
            }
        }
        .foregroundStyle(InputMetrics.icon(state, leading: leading))
        .animation(InputMetrics.animation, value: state)
        .accessibilityHidden(true)
    }
}
