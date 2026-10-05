// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// A selectable pill for multi-select tags ("Too salty", "Tender"). The DS says a
/// selectable pill is an `sm` AppButton, but AppButton has no selected state, so this
/// draws the `sm` capsule itself: `spacing-11` tall, `spacing-3` side padding,
/// `sans-sm`. At rest `panel` + `text-primary`; on, `primary-soft` + `primary-text`
/// semibold. Press `opacity-70`; the parent plays the haptic.
struct TagToggle: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(OptionCell<EmptyView>.selectionAnimation(reduceMotion: reduceMotion)) { action() }
        } label: {
            Text(title)
                .textStyle(.sansSm, tone: nil, weight: isOn ? .semibold : nil, lines: 1)
                .foregroundStyle(isOn ? DS.Color.primaryText : DS.Color.textPrimary)
                .padding(.horizontal, DS.Spacing.s3)
                .frame(minHeight: DS.Spacing.s11)
                .background(Capsule().fill(isOn ? DS.Color.primarySoft : DS.Color.panel))
                .contentShape(Capsule())
        }
        .buttonStyle(AppPressableButtonStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var on: Set<String> = ["Tender"]

    WrappingHStack(spacing: DS.Spacing.s2, lineSpacing: DS.Spacing.s2) {
        ForEach(["Tasty", "Tender", "Too salty", "Dry", "Comforting"], id: \.self) { tag in
            TagToggle(title: tag, isOn: on.contains(tag)) {
                if on.contains(tag) { on.remove(tag) } else { on.insert(tag) }
            }
        }
    }
    .padding(DS.Spacing.gutter)
    .background(DS.Color.sheet)
}
