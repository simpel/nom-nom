import SwiftUI

/// Centralized single-line input component for Nom Nom.
///
/// Implements consistent sizing, background styling, borders, focus state rings,
/// and icon placement across all screens, matching AppButton conventions.
struct Input: View {
    var placeholder: String = ""
    @Binding var text: String
    var leadingIcon: AppInputIcon? = nil
    var trailingIcon: AppInputIcon? = nil
    var size: AppInputSize = .md
    var style: AppInputStyle = .filled
    var shape: AppInputShape = .rounded()
    var clearable: Bool = false
    var isError: Bool = false
    var disabled: Bool = false
    var ghostText: String? = nil
    var externalFocus: FocusState<Bool>.Binding? = nil

    @FocusState private var internalFocus: Bool

    init(
        _ placeholder: String = "",
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
        self.placeholder = placeholder
        self._text = text
        if let leadingIcon {
            self.leadingIcon = leadingIcon
        } else if let leadingSystemImage {
            self.leadingIcon = .system(leadingSystemImage)
        } else {
            self.leadingIcon = nil
        }
        if let trailingIcon {
            self.trailingIcon = trailingIcon
        } else if let trailingSystemImage {
            self.trailingIcon = .system(trailingSystemImage)
        } else {
            self.trailingIcon = nil
        }
        self.size = size
        self.style = style
        self.shape = shape
        self.clearable = clearable
        self.isError = isError
        self.disabled = disabled
        self.ghostText = ghostText
        self.externalFocus = isFocused
    }

    private var isFocused: Bool {
        externalFocus?.wrappedValue ?? internalFocus
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let leadingIcon {
                iconView(for: leadingIcon)
            }

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(size.font)
                        .foregroundStyle(DS.Color.textTertiary)
                        .allowsHitTesting(false)
                        .lineLimit(1)
                }

                if let ghost = ghostText, !ghost.isEmpty {
                    HStack(spacing: 0) {
                        Text(text).foregroundStyle(.clear)
                        Text(ghost).foregroundStyle(DS.Color.textTertiary)
                    }
                    .font(size.font)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                }

                textField
            }

            if clearable && !text.isEmpty && !disabled {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(size.font)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear text")
            }

            if let trailingIcon {
                iconView(for: trailingIcon)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size.height)
        .padding(.horizontal, style == .plain ? 0 : size.horizontalPadding)
        .background(containerBackground)
        .clipShape(containerShape)
        .overlay {
            containerBorder
        }
        .contentShape(containerShape)
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .animation(.easeOut(duration: 0.15), value: isError)
        .opacity(disabled ? 0.5 : 1.0)
    }

    // MARK: - Subviews & Controls

    @ViewBuilder
    private var textField: some View {
        if let externalFocus {
            TextField("", text: $text)
                .font(size.font)
                .foregroundStyle(disabled ? DS.Color.textTertiary : DS.Color.textPrimary)
                .disabled(disabled)
                .focused(externalFocus)
        } else {
            TextField("", text: $text)
                .font(size.font)
                .foregroundStyle(disabled ? DS.Color.textTertiary : DS.Color.textPrimary)
                .disabled(disabled)
                .focused($internalFocus)
        }
    }

    @ViewBuilder
    private func iconView(for icon: AppInputIcon) -> some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(size.font)
                .foregroundStyle(isFocused ? DS.Color.accent : DS.Color.textSecondary)
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)
        case .image(let img):
            img
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)
        }
    }

    // MARK: - Shapes & Styling

    private var containerShape: some Shape {
        switch shape {
        case .capsule:
            return AnyShape(Capsule())
        case .rounded(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        switch style {
        case .filled:
            DS.Color.sunken
        case .outlined, .plain:
            Color.clear
        }
    }

    @ViewBuilder
    private var containerBorder: some View {
        if style != .plain, let borderColor {
            let width: CGFloat = (isFocused || isError) ? 1.5 : 0.5
            switch shape {
            case .capsule:
                Capsule().strokeBorder(borderColor, lineWidth: width)
            case .rounded(let radius):
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: width)
            }
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

typealias AppInput = Input
