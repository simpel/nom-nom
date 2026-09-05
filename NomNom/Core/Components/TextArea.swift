import SwiftUI

/// A harmonized, multi-line text input component adhering to Nom Nom design tokens.
/// Provides consistent padding, sunken background, subtle border, and focus state across all textareas.
struct TextArea: View {
    let placeholder: String
    @Binding var text: String
    var lineLimit: ClosedRange<Int>
    var font: Font
    var cornerRadius: CGFloat

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String = "",
        text: Binding<String>,
        lineLimit: ClosedRange<Int> = 3...6,
        font: Font = .body,
        cornerRadius: CGFloat = AppRadius.input
    ) {
        self.placeholder = placeholder
        self._text = text
        self.lineLimit = lineLimit
        self.font = font
        self.cornerRadius = cornerRadius
    }

    init(
        _ placeholder: String = "",
        text: Binding<String>,
        lines: Int,
        font: Font = .body,
        cornerRadius: CGFloat = AppRadius.input
    ) {
        self.init(
            placeholder,
            text: text,
            lineLimit: lines...lines,
            font: font,
            cornerRadius: cornerRadius
        )
    }

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(font)
            .lineLimit(lineLimit)
            .foregroundStyle(DS.Color.textPrimary)
            .focused($isFocused)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DS.Color.sunken)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? DS.Color.accent.opacity(0.6) : DS.Color.line.opacity(0.35),
                        lineWidth: isFocused ? 1.0 : 0.5
                    )
            }
            .animation(.easeInOut(duration: 0.15), value: isFocused)
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
