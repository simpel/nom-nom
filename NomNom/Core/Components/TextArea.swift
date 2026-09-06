import SwiftUI

/// A harmonized, multi-line text input component adhering to Nom Nom design tokens.
/// Provides consistent padding, sunken background, subtle border, and focus state across all textareas.
struct TextArea: View {
    var placeholder: String = ""
    @Binding var text: String
    var lineLimit: ClosedRange<Int>
    var font: Font
    var cornerRadius: CGFloat
    var style: AppInputStyle
    var isError: Bool
    var disabled: Bool
    var externalFocus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    init(
        _ placeholder: String = "",
        text: Binding<String>,
        lineLimit: ClosedRange<Int> = 3...6,
        font: Font = .body,
        cornerRadius: CGFloat = AppRadius.input,
        style: AppInputStyle = .filled,
        isError: Bool = false,
        disabled: Bool = false,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.lineLimit = lineLimit
        self.font = font
        self.cornerRadius = cornerRadius
        self.style = style
        self.isError = isError
        self.disabled = disabled
        self.externalFocus = isFocused
    }

    init(
        _ placeholder: String = "",
        text: Binding<String>,
        lines: Int,
        font: Font = .body,
        cornerRadius: CGFloat = AppRadius.input,
        style: AppInputStyle = .filled,
        isError: Bool = false,
        disabled: Bool = false,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder,
            text: text,
            lineLimit: lines...lines,
            font: font,
            cornerRadius: cornerRadius,
            style: style,
            isError: isError,
            disabled: disabled,
            isFocused: isFocused
        )
    }

    private var isFocused: Bool {
        externalFocus?.wrappedValue ?? internalFocus
    }

    var body: some View {
        editorField
            .font(font)
            .lineLimit(lineLimit)
            .foregroundStyle(disabled ? DS.Color.textTertiary : DS.Color.textPrimary)
            .disabled(disabled)
            .padding(.horizontal, style == .plain ? 0 : 14)
            .padding(.vertical, style == .plain ? 0 : 10)
            .background {
                if style == .filled {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(DS.Color.sunken)
                }
            }
            .overlay {
                if style != .plain, let borderColor {
                    let width: CGFloat = (isFocused || isError) ? 1.5 : 0.5
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: width)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.15), value: isError)
            .opacity(disabled ? 0.5 : 1.0)
    }

    @ViewBuilder
    private var editorField: some View {
        if let externalFocus {
            TextField(placeholder, text: $text, axis: .vertical)
                .focused(externalFocus)
        } else {
            TextField(placeholder, text: $text, axis: .vertical)
                .focused($internalFocus)
        }
    }

    private var borderColor: Color? {
        if isError {
            return Color.red.opacity(0.8)
        }
        if isFocused {
            return DS.Color.accent.opacity(0.8)
        }
        switch style {
        case .filled:
            return DS.Color.line.opacity(0.35)
        case .outlined:
            return DS.Color.lineStrong
        case .plain:
            return nil
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TextArea("Describe your dinner party...", text: .constant(""))
        TextArea("Add any adjustments...", text: .constant("Made extra crispy with homemade salsa verde!"))
    }
    .padding()
    .background(DS.Color.bg)
}
