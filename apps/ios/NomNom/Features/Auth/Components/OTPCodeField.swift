import SwiftUI
import UIKit

/// Six separate input cells for one-time verification codes (OTP).
///
/// Handles keyboard typing, backspace deletion, iOS QuickType SMS/Mail autofill,
/// and pasting complete verification codes from the clipboard.
///
/// Not synced with the DS (README "Kept as-is"): each cell borrows Input's ground,
/// radius and state borders (`InputMetrics`) at the labelled-field height (`s14`),
/// with the digit in `sans-xl` semibold tabular (README: "large sans figures").
struct OTPCodeField: View {
    @Binding var code: String
    var numberOfDigits: Int = 6
    var isError: Bool = false
    var onComplete: ((String) -> Void)? = nil
    var onEdit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Visual individual cells
            HStack(spacing: DS.Spacing.s2) {
                ForEach(0..<numberOfDigits, id: \.self) { index in
                    digitCell(at: index)
                }
            }

            // Invisible text field on top handling focus, keyboard input, and paste
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .frame(height: InputMetrics.labeledHeight)
        .onAppear {
            isFocused = true
        }
        .onChange(of: code) { oldValue, newValue in
            onEdit?()
            handleCodeChange(oldValue: oldValue, newValue: newValue)
        }
    }

    // MARK: - Digit Cell

    @ViewBuilder
    private func digitCell(at index: Int) -> some View {
        let isCurrent = isFocused && (code.count < numberOfDigits ? index == code.count : false)
        let character: String? = {
            if index < code.count {
                let stringIndex = code.index(code.startIndex, offsetBy: index)
                return String(code[stringIndex])
            }
            return nil
        }()

        let state = InputState(focused: isCurrent, error: isError, readOnly: false, disabled: false)
        let border = InputMetrics.border(.soft, state: state)

        ZStack {
            if let character {
                Text(character)
                    .textStyle(.sansXl, weight: .semibold, numeric: true)
            } else if isCurrent {
                BlinkingCursor()
            } else {
                // Input README: placeholders are `text-tertiary`.
                Text("0")
                    .textStyle(.sansXl, tone: .tertiary, weight: .semibold, numeric: true)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: InputMetrics.labeledHeight)
        .background(InputMetrics.background(.soft), in: InputMetrics.shape)
        .overlay {
            if let border {
                InputMetrics.shape.strokeBorder(border.color, lineWidth: border.width)
            }
        }
        .animation(InputMetrics.animation, value: state)
    }

    // MARK: - Change & Paste Handler

    private func handleCodeChange(oldValue: String, newValue: String) {
        let digits = newValue.filter(\.isNumber)
        let sanitized: String

        // Handle pasting or autofill (multiple characters added at once)
        if newValue.count - oldValue.count >= 2 {
            if let clip = UIPasteboard.general.string?.filter(\.isNumber),
               !clip.isEmpty,
               digits.contains(clip) {
                sanitized = String(clip.prefix(numberOfDigits))
            } else if digits.count > numberOfDigits && !oldValue.isEmpty {
                sanitized = String(digits.suffix(numberOfDigits))
            } else {
                sanitized = String(digits.prefix(numberOfDigits))
            }
        } else {
            sanitized = String(digits.prefix(numberOfDigits))
        }

        if code != sanitized {
            code = sanitized
        }

        if sanitized.count == numberOfDigits && (oldValue != sanitized || oldValue.count != numberOfDigits) {
            onComplete?(sanitized)
        }
    }
}

// MARK: - Blinking Cursor

private struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        // A `border-thick` caret as tall as the digit step; the DS has no caret or blink
        // timing, so it blinks over `duration-layout` (DS-GAPS.md, "shell").
        Capsule()
            .fill(DS.Color.primary)
            .frame(width: DS.BorderWidth.thick, height: DS.TextStyle.sansXl.size)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(DS.Motion.layout.repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
