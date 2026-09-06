import SwiftUI
import UIKit

/// Six separate input cells for one-time verification codes (OTP).
///
/// Handles keyboard typing, backspace deletion, iOS QuickType SMS/Mail autofill,
/// and pasting complete verification codes from the clipboard.
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
            HStack(spacing: 8) {
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
                .accentColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .frame(maxWidth: 340)
        .frame(height: 56)
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

        let borderColor: Color = {
            if isError {
                return Color.red.opacity(0.8)
            } else if isCurrent {
                return DS.Color.textPrimary
            } else {
                return DS.Color.line.opacity(0.35)
            }
        }()

        let borderWidth: CGFloat = {
            if isError {
                return 1.0
            } else if isCurrent {
                return 1.5
            } else {
                return 0.5
            }
        }()

        ZStack {
            if let character {
                Text(character)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(DS.Color.textPrimary)
            } else if isCurrent {
                BlinkingCursor()
            } else {
                Text("0")
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color(uiColor: .placeholderText))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
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
        Capsule()
            .fill(DS.Color.textPrimary)
            .frame(width: 2, height: 22)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
