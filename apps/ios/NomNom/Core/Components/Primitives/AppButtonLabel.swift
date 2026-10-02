import SwiftUI

/// The AppButton capsule as a plain view, for controls that bring their own
/// tap handling: `PhotosPicker`, `ShareLink`, `Menu` and `NavigationLink` labels.
/// Wrap it in `.buttonStyle(AppPressableButtonStyle())` for the shared press.
struct AppButtonLabel: View {
    private let title: String?
    private let icon: AppButtonIcon?
    private let iconPosition: DSIconPosition
    private let variant: DSVariant
    private let appearance: DSAppearance
    private let size: AppButtonSize
    private let fullWidth: Bool
    private let isLoading: Bool
    private let accessibilityLabel: String?
    /// Icon-only diameter. Always `AppButtonSize.iconOnlyDiameter` (44) except for the
    /// deprecated sized icon-only API, which keeps `lg` at 48 until its callers migrate.
    private let iconOnlyDiameter: CGFloat
    /// Overrides the icon's ink only (PhotoCard's favourite heart: `destructive-text`
    /// when on, components/PhotoCard/README.md). Nil inks it like the label.
    private let iconColor: Color?

    @Environment(\.isEnabled) private var isEnabled

    /// A labelled capsule.
    init(
        _ title: String,
        icon: AppButtonIcon? = nil,
        iconPosition: DSIconPosition = .start,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .solid,
        size: AppButtonSize = .md,
        fullWidth: Bool = false,
        isLoading: Bool = false
    ) {
        self.init(title: title, icon: icon, iconPosition: iconPosition, variant: variant, appearance: appearance,
                  size: size, fullWidth: fullWidth, isLoading: isLoading, accessibilityLabel: nil)
    }

    /// An icon-only 44 × 44 circle; `accessibilityLabel` is its spoken name. There is
    /// one icon-only size, so it takes none.
    init(
        icon: AppButtonIcon,
        accessibilityLabel: String,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .solid,
        isLoading: Bool = false,
        iconColor: Color? = nil
    ) {
        self.init(title: nil, icon: icon, iconPosition: .start, variant: variant, appearance: appearance,
                  size: .md, fullWidth: false, isLoading: isLoading, accessibilityLabel: accessibilityLabel,
                  iconColor: iconColor)
    }

    /// Pre-v3 API: `title: nil` drew an icon-only circle sized by `size`.
    @_disfavoredOverload
    @available(*, deprecated, message: "Use AppButtonLabel(_:icon:…) or AppButtonLabel(icon:accessibilityLabel:…)")
    init(
        _ title: String?,
        icon: AppButtonIcon? = nil,
        iconPosition: DSIconPosition = .start,
        variant: DSVariant = .primary,
        appearance: DSAppearance = .solid,
        size: AppButtonSize = .md,
        fullWidth: Bool = false,
        isLoading: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.init(title: title, icon: icon, iconPosition: iconPosition, variant: variant, appearance: appearance,
                  size: size, fullWidth: fullWidth, isLoading: isLoading, accessibilityLabel: accessibilityLabel,
                  iconOnlyDiameter: max(size.height, AppButtonSize.iconOnlyDiameter))
    }

    init(
        title: String?,
        icon: AppButtonIcon?,
        iconPosition: DSIconPosition,
        variant: DSVariant,
        appearance: DSAppearance,
        size: AppButtonSize,
        fullWidth: Bool,
        isLoading: Bool,
        accessibilityLabel: String?,
        iconOnlyDiameter: CGFloat = AppButtonSize.iconOnlyDiameter,
        iconColor: Color? = nil
    ) {
        self.iconColor = iconColor
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.variant = variant
        self.appearance = appearance
        self.size = size
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.accessibilityLabel = accessibilityLabel
        self.iconOnlyDiameter = iconOnlyDiameter
    }

    private var paint: DSPaint { DSPaint(variant: variant, appearance: appearance) }
    private var isIconOnly: Bool { title?.isEmpty ?? true }

    var body: some View {
        HStack(spacing: size.gap) {
            if iconPosition == .end {
                titleText
                tintedIconSlot
            } else {
                tintedIconSlot
                titleText
            }
        }
        .textStyle(size.textStyle, tone: nil, weight: .semibold, lines: 1)
        .foregroundStyle(paint.foreground)
        .padding(.horizontal, isIconOnly ? 0 : size.horizontalPadding)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(width: isIconOnly && !fullWidth ? iconOnlyDiameter : nil)
        .frame(
            minWidth: AppButtonSize.minimumTarget,
            minHeight: isIconOnly ? iconOnlyDiameter : size.height
        )
        .background(paint.background, in: Capsule())
        .overlay {
            if let border = paint.border {
                Capsule().strokeBorder(border, lineWidth: DSAppearance.outlineBorderWidth)
            }
        }
        .modifier(ElevationModifier(isElevated: paint.isElevated))
        .contentShape(Capsule())
        // README "Motion and states": "Disabled: `opacity-50` on buttons". A pending
        // button is not disabled, so it does not fade.
        .opacity(!isEnabled && !isLoading ? DS.Opacity.disabled : DS.Opacity.o100)
        .accessibilityElement(children: .combine)
        .modifier(OptionalAccessibilityLabel(label: accessibilityLabel))
    }

    @ViewBuilder
    private var titleText: some View {
        if let title, !title.isEmpty {
            Text(title)
        }
    }

    private var tintedIconSlot: some View {
        iconSlot.foregroundStyle(iconColor ?? paint.foreground)
    }

    /// "Pending: a spinner replaces the button icon."
    @ViewBuilder
    private var iconSlot: some View {
        if isLoading {
            ProgressView()
                .controlSize(size.spinnerSize)
                .tint(paint.foreground)
        } else if let icon {
            switch icon {
            case .system(let name):
                Image(systemName: name)
            case .asset(let name):
                Image(name).resizable().scaledToFit()
                    .frame(width: size.iconSize, height: size.iconSize)
            case .image(let image):
                image.resizable().scaledToFit()
                    .frame(width: size.iconSize, height: size.iconSize)
            case .text(let glyph):
                Text(glyph).monospacedDigit()
            }
        }
    }
}

private struct OptionalAccessibilityLabel: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        if let label {
            content.accessibilityLabel(label)
        } else {
            content
        }
    }
}

private struct ElevationModifier: ViewModifier {
    let isElevated: Bool

    func body(content: Content) -> some View {
        if isElevated {
            content.dsShadow(.xs)
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: DS.Spacing.s3) {
        AppButtonLabel("Add photo", icon: "camera", variant: .secondary, appearance: .elevated, size: .sm)
        AppButtonLabel("Share", icon: "square.and.arrow.up", appearance: .soft)
        AppButtonLabel(icon: "ellipsis", accessibilityLabel: "More", variant: .secondary, appearance: .soft)
    }
    .padding(DS.Spacing.s4)
    .background(DS.Color.bg)
}
