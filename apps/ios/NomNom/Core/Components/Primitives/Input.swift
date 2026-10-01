import SwiftUI

/// The single-line text field: one height (`s11`, `s14` with a label) and one
/// radius (`radius-xl`) for every field; `soft`, `outline` or `plain`, with
/// optional icons and a clear button.
///
/// Focus: 1.5pt `primary` at 80%, leading icon to `primary`, label to `primary-text`.
/// Error: 1.5pt `destructive` at 80%. Disabled: 50% opacity, `text-tertiary`.
struct Input: View {
    var label: String?
    var placeholder: String
    @Binding var text: String
    var leadingIcon: AppInputIcon?
    var trailingIcon: AppInputIcon?
    var appearance: InputAppearance
    var clearable: Bool
    var isError: Bool
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
        isError: Bool = false,
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
        self.isError = isError
        self.disabled = disabled
        self.ghostText = ghostText
        self.externalFocus = isFocused
    }

    /// A labelled field; `plain` by default because labelled fields sit in form rows.
    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        leadingIcon: AppInputIcon? = nil,
        trailingIcon: AppInputIcon? = nil,
        appearance: InputAppearance = .plain,
        clearable: Bool = false,
        isError: Bool = false,
        disabled: Bool = false,
        ghostText: String? = nil,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder, label: label, text: text,
            leadingIcon: leadingIcon, trailingIcon: trailingIcon, appearance: appearance,
            clearable: clearable, isError: isError, disabled: disabled,
            ghostText: ghostText, isFocused: isFocused
        )
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }
    private var hasLabel: Bool { !(label ?? "").isEmpty }
    private var textColor: Color { disabled ? DS.Color.textTertiary : DS.Color.textPrimary }

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            if let leadingIcon { iconView(leadingIcon, tinted: true) }

            VStack(alignment: .leading, spacing: 0) {
                if let label, hasLabel {
                    Text(label)
                        .textStyle(.sansXs, tone: nil)
                        .foregroundStyle(isFocused ? DS.Color.primaryText : DS.Color.textSecondary)
                        .lineLimit(1)
                }
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .textStyle(.sansMd, tone: .tertiary)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }
                    if let ghostText, !ghostText.isEmpty {
                        (Text(text).foregroundStyle(.clear) + Text(ghostText).foregroundStyle(DS.Color.textTertiary))
                            .textStyle(.sansMd, tone: nil)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }
                    field
                }
            }

            if clearable && !text.isEmpty && !disabled {
                AppButton(
                    icon: "xmark",
                    accessibilityLabel: "Clear text",
                    variant: .secondary,
                    appearance: .ghost,
                    size: .sm
                ) { text = "" }
            }

            if let trailingIcon { iconView(trailingIcon, tinted: false) }
        }
        .frame(maxWidth: .infinity)
        .frame(height: hasLabel ? InputMetrics.labeledHeight : InputMetrics.height)
        .padding(.horizontal, appearance == .plain ? 0 : InputMetrics.sidePadding)
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
    private var field: some View {
        let base = TextField("", text: $text)
            .textStyle(.sansMd, tone: nil)
            .foregroundStyle(textColor)
            .disabled(disabled)
            .accessibilityLabel(label ?? placeholder)
        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }

    @ViewBuilder
    private func iconView(_ icon: AppInputIcon, tinted: Bool) -> some View {
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
        .foregroundStyle(tinted && isFocused ? DS.Color.primary : DS.Color.textSecondary)
        .accessibilityHidden(true)
    }
}

typealias AppInput = Input

private struct InputGallery: View {
    @State private var name = "Carbonara"
    @State private var empty = ""

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            Input("Search recipes", text: $empty, leadingIcon: "magnifyingglass")
            Input("Recipe name", text: $name, clearable: true)
            Input("Party name", text: $empty, appearance: .outline)
            Input("Email", label: "Email", text: $empty, appearance: .soft)
            Input("Quantity", text: $name, isError: true)
            Input("Disabled", text: $name, disabled: true)
            Card { Input(label: "First name", placeholder: "Anna", text: $empty) }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { InputGallery() }
#Preview("Dark") { InputGallery().preferredColorScheme(.dark) }
