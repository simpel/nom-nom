import SwiftUI

/// The one switch: an on/off setting, always the trailing slot of a ListRow whose
/// title names the setting. No label is drawn beside it and there is no "On"/"Off"
/// text: the position is the state. Named `AppToggle` because `Toggle` would shadow
/// `SwiftUI.Toggle` (README: names carry a prefix only where they collide).
///
/// Track `spacing-12` × `spacing-7`, `radius-full`: `track` off, `primary` on. Knob
/// `spacing-6`, `stone-0`, `shadow-xs`. It is the one control drawn under 44pt, so it
/// carries a 44pt-tall hit area. Pressing scales the knob (`scale-knob`) instead of
/// fading the control; disabled is `opacity-50`, as on AppButton. One size.
struct AppToggle: View {
    @Binding var isOn: Bool
    /// Accessible name: the row's title.
    let label: String

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        SwiftUI.Toggle(label, isOn: $isOn)
            .toggleStyle(DSToggleStyle())
    }
}

/// The DS switch as a `ToggleStyle`, so a `SwiftUI.Toggle` keeps its switch semantics
/// for VoiceOver. The label is never drawn (the Toggle README puts the switch in a
/// ListRow's trailing slot, the row title beside it); it is the spoken name.
struct DSToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            DSToggleTrack(isOn: configuration.isOn)
        }
        .buttonStyle(DSToggleKnobPressStyle(isOn: configuration.isOn))
        .accessibilityRepresentation {
            SwiftUI.Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

/// Track and knob at rest; the press state is drawn by `DSToggleKnobPressStyle`.
private struct DSToggleTrack: View {
    let isOn: Bool
    var isPressed = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Capsule()
            .fill(isOn ? DS.Color.primary : DS.Color.track)
            .frame(width: DS.Spacing.s12, height: DS.Spacing.s7)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(DS.Color.Stone.stone0)
                    .frame(width: DS.Spacing.s6, height: DS.Spacing.s6)
                    .dsShadow(.xs)
                    .scaleEffect(isPressed && !reduceMotion ? DS.Motion.scaleKnob : 1)
                    .padding(.horizontal, DS.Spacing.s0_5)
            }
            // A switch is drawn at its own size; its target is 44pt tall.
            .frame(minHeight: AppButtonSize.minimumTarget)
            .contentShape(Rectangle())
            .opacity(isEnabled ? DS.Opacity.o100 : DS.Opacity.disabled)
            // bundle.css `.nn-toggle__knob`: one `duration-state` transform transition
            // carries both the slide and the press scale.
            .animation(reduceMotion ? nil : DS.Motion.state, value: isOn)
            .animation(DS.Motion.state, value: isPressed)
    }
}

private struct DSToggleKnobPressStyle: ButtonStyle {
    let isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        DSToggleTrack(isOn: isOn, isPressed: configuration.isPressed)
    }
}

private struct AppTogglePreview: View {
    @State private var reminder = true
    @State private var digest = false

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            HStack {
                Text("Dinner reminder").textStyle(.sansMd)
                Spacer()
                AppToggle("Dinner reminder", isOn: $reminder)
            }
            HStack {
                Text("Weekly digest").textStyle(.sansMd)
                Spacer()
                AppToggle("Weekly digest", isOn: $digest)
            }
            HStack {
                Text("Disabled").textStyle(.sansMd)
                Spacer()
                AppToggle("Disabled", isOn: .constant(true)).disabled(true)
            }
        }
        .padding(DS.Spacing.cardPadding)
        .background(DS.Color.panel)
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { AppTogglePreview() }
#Preview("Dark") { AppTogglePreview().preferredColorScheme(.dark) }
