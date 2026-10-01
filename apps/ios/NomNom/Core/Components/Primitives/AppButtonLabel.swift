import SwiftUI

/// The AppButton capsule as a plain view, for controls that bring their own
/// tap handling: `PhotosPicker`, `ShareLink`, `Menu` and `NavigationLink` labels.
/// Pass `title: nil` for a circular icon-only label (set `accessibilityLabel`).
struct AppButtonLabel: View {
    var title: String?
    var icon: AppButtonIcon?
    var iconPosition: DSIconPosition
    var variant: DSVariant
    var appearance: DSAppearance
    var size: AppButtonSize
    var fullWidth: Bool
    var isLoading: Bool
    var accessibilityLabel: String?

    @Environment(\.isEnabled) private var isEnabled

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
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.variant = variant
        self.appearance = appearance
        self.size = size
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.accessibilityLabel = accessibilityLabel
    }

    private var paint: DSPaint { DSPaint(variant: variant, appearance: appearance) }
    private var isIconOnly: Bool { title?.isEmpty ?? true }

    var body: some View {
        HStack(spacing: size.gap) {
            if iconPosition == .end {
                titleText
                iconSlot
            } else {
                iconSlot
                titleText
            }
        }
        .textStyle(size.textStyle, tone: nil, weight: .semibold)
        .lineLimit(1)
        .foregroundStyle(paint.foreground)
        .padding(.horizontal, isIconOnly ? 0 : size.horizontalPadding)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(width: isIconOnly && !fullWidth ? size.height : nil)
        .frame(minHeight: size.height)
        .background(paint.background, in: Capsule())
        .overlay {
            if let border = paint.border {
                Capsule().strokeBorder(border, lineWidth: DSAppearance.outlineWidth)
            }
        }
        .modifier(ElevationModifier(isElevated: paint.isElevated))
        .contentShape(Capsule())
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
        AppButtonLabel(nil, icon: "ellipsis", variant: .secondary, appearance: .soft, accessibilityLabel: "More")
    }
    .padding(DS.Spacing.s4)
    .background(DS.Color.bg)
}
