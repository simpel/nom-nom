import SwiftUI

// Pre-design-system Input/TextArea API, kept so existing call sites compile until
// Phase 5. `size` and `shape` are ignored (one height, `radius-xl`); `style` maps
// `.filled` → soft, `.outlined` → outline, `.cardRow`/`.plain` → plain.

extension Input {
    @_disfavoredOverload
    @available(*, deprecated, message: "Use Input(_:label:text:leadingIcon:trailingIcon:appearance:…); size and shape are gone")
    init(
        _ placeholder: String = "",
        label: String? = nil,
        text: Binding<String>,
        leadingIcon: AppInputIcon? = nil,
        leadingSystemImage: String? = nil,
        trailingIcon: AppInputIcon? = nil,
        trailingSystemImage: String? = nil,
        size: AppInputSize = .md,
        style: AppInputStyle = .filled,
        shape: AppInputShape = .rounded(),
        clearable: Bool = false,
        isError: Bool = false,
        disabled: Bool = false,
        ghostText: String? = nil,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder,
            label: label,
            text: text,
            leadingIcon: leadingIcon ?? leadingSystemImage.map { .system($0) },
            trailingIcon: trailingIcon ?? trailingSystemImage.map { .system($0) },
            appearance: style.appearance,
            clearable: clearable,
            isError: isError,
            disabled: disabled,
            ghostText: ghostText,
            isFocused: isFocused
        )
    }

    @_disfavoredOverload
    @available(*, deprecated, message: "Use Input(label:placeholder:text:…:appearance:…); size and shape are gone")
    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        leadingIcon: AppInputIcon? = nil,
        leadingSystemImage: String? = nil,
        trailingIcon: AppInputIcon? = nil,
        trailingSystemImage: String? = nil,
        size: AppInputSize = .md,
        style: AppInputStyle = .cardRow,
        shape: AppInputShape = .rounded(),
        clearable: Bool = false,
        isError: Bool = false,
        disabled: Bool = false,
        ghostText: String? = nil,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder,
            label: label,
            text: text,
            leadingIcon: leadingIcon ?? leadingSystemImage.map { .system($0) },
            trailingIcon: trailingIcon ?? trailingSystemImage.map { .system($0) },
            appearance: style.appearance,
            clearable: clearable,
            isError: isError,
            disabled: disabled,
            ghostText: ghostText,
            isFocused: isFocused
        )
    }
}

extension TextArea {
    /// `font` and `cornerRadius` are ignored: text is `sans-md`, the radius `radius-xl`.
    @_disfavoredOverload
    @available(*, deprecated, message: "Use TextArea(_:label:text:lineLimit:appearance:…); font and cornerRadius are gone")
    init(
        _ placeholder: String = "",
        text: Binding<String>,
        lineLimit: ClosedRange<Int> = 3...6,
        font: Font = .body,
        cornerRadius: CGFloat = DS.Radius.xl,
        style: AppInputStyle = .filled,
        isError: Bool = false,
        disabled: Bool = false,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder,
            text: text,
            lineLimit: lineLimit,
            appearance: style.appearance,
            isError: isError,
            disabled: disabled,
            isFocused: isFocused
        )
    }

    @_disfavoredOverload
    @available(*, deprecated, message: "Use TextArea(_:label:text:lineLimit:appearance:…) with lineLimit: n...n")
    init(
        _ placeholder: String = "",
        text: Binding<String>,
        lines: Int,
        font: Font = .body,
        cornerRadius: CGFloat = DS.Radius.xl,
        style: AppInputStyle = .filled,
        isError: Bool = false,
        disabled: Bool = false,
        isFocused: FocusState<Bool>.Binding? = nil
    ) {
        self.init(
            placeholder,
            text: text,
            lineLimit: lines...lines,
            appearance: style.appearance,
            isError: isError,
            disabled: disabled,
            isFocused: isFocused
        )
    }
}
