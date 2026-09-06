import SwiftUI

/// Centralized NomNom button component.
///
/// Implements consistent full-capsule styling, typography, contrast, and icon placement across
/// primary, secondary, neutral, and destructive variants in normal, outlined, and ghost presentations.
struct AppButton: View {
    var title: String = ""
    var icon: AppButtonIcon? = nil
    var iconPosition: AppButtonIconPosition = .leading
    var variant: AppButtonVariant = .primary
    var style: AppButtonStyle = .normal
    var size: AppButtonSize = .md
    var isFullWidth: Bool = false
    var isPending: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    init(
        _ title: String = "",
        icon: AppButtonIcon? = nil,
        systemImage: String? = nil,
        iconPosition: AppButtonIconPosition = .leading,
        variant: AppButtonVariant = .primary,
        style: AppButtonStyle = .normal,
        size: AppButtonSize = .md,
        isFullWidth: Bool = false,
        isPending: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        if let icon {
            self.icon = icon
        } else if let systemImage {
            self.icon = .system(systemImage)
        } else {
            self.icon = nil
        }
        self.iconPosition = iconPosition
        self.variant = variant
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isPending = isPending
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: title.isEmpty ? 0 : 8) {
                if iconPosition == .trailing {
                    titleLabel
                    trailingIndicatorOrIcon
                } else {
                    leadingIndicatorOrIcon
                    titleLabel
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(width: (title.isEmpty && !isFullWidth) ? size.height : nil)
            .frame(height: size.height)
            .padding(.horizontal, title.isEmpty ? 0 : size.horizontalPadding)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                if let borderColor {
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: style == .outlined ? 1.5 : 0)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(AppPressableButtonStyle())
        .disabled(disabled || isPending)
        .opacity((disabled && !isPending) ? 0.45 : 1.0)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var titleLabel: some View {
        if !title.isEmpty {
            Text(title)
                .font(size.font)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private var leadingIndicatorOrIcon: some View {
        if isPending {
            progressIndicator
        } else {
            iconView
        }
    }

    @ViewBuilder
    private var trailingIndicatorOrIcon: some View {
        if isPending {
            progressIndicator
        } else {
            iconView
        }
    }

    @ViewBuilder
    private var progressIndicator: some View {
        ProgressView()
            .controlSize(size == .sm ? .mini : .small)
            .tint(foregroundColor)
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            switch icon {
            case .system(let name):
                Image(systemName: name)
                    .font(size.font.weight(.semibold))
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
    }

    // MARK: - Color Logic

    private var backgroundColor: Color {
        switch style {
        case .ghost, .outlined:
            return .clear
        case .normal:
            switch variant {
            case .primary:
                return DS.Color.accent
            case .secondary:
                return DS.Color.accentSoft
            case .neutral:
                return Color(uiColor: .systemGray5)
            case .destructive:
                return .red
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .normal:
            switch variant {
            case .primary:
                return .white
            case .secondary:
                return DS.Color.accentText
            case .neutral:
                return DS.Color.textPrimary
            case .destructive:
                return .white
            }
        case .outlined:
            switch variant {
            case .primary:
                return DS.Color.accent
            case .secondary:
                return DS.Color.accentText
            case .neutral:
                return DS.Color.textPrimary
            case .destructive:
                return .red
            }
        case .ghost:
            switch variant {
            case .primary:
                return DS.Color.accent
            case .secondary:
                return DS.Color.accentText
            case .neutral:
                // High-contrast neutral gray (WCAG AAA compliant on light and dark)
                return DS.Color.textSecondary
            case .destructive:
                return .red
            }
        }
    }

    private var borderColor: Color? {
        guard style == .outlined else { return nil }
        switch variant {
        case .primary:
            return DS.Color.accent
        case .secondary:
            return DS.Color.lineStrong
        case .neutral:
            return DS.Color.lineStrong
        case .destructive:
            return .red
        }
    }
}
