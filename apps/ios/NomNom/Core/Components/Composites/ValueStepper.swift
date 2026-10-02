import SwiftUI

/// ValueStepper sizes. Both use AppButton's one 44pt icon-only circle; the readout is
/// `spacing-10` wide at `md` and `spacing-8` at `sm` (bundle.css `.nn-stepper__value`).
enum ValueStepperSize: Equatable {
    case sm, md

    var readoutWidth: CGFloat { self == .sm ? DS.Spacing.s8 : DS.Spacing.s10 }
}

/// Minus · numeral · plus (components/ValueStepper/README.md): two AppButton
/// `secondary soft` icon-only buttons `spacing-2` either side of a `sans-lg` tabular
/// readout, fixed-width so the buttons never shift as digits change. At a limit the
/// matching button is disabled, never hidden. VoiceOver gets one adjustable element.
///
/// The numeral stands alone by default; pass `unit` only when nothing beside the
/// stepper names the number.
///
/// ```swift
/// ValueStepper(value: $servings, in: 1...12, label: "Servings")          // in a labelled row
/// ValueStepper(value: $servings, in: 1...12, unit: "servings", label: "Servings")
/// ```
struct ValueStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int
    var unit: String?
    var formatValue: ((Int) -> String)?
    var size: ValueStepperSize
    var label: String

    init(
        value: Binding<Int>,
        in range: ClosedRange<Int> = 1...99,
        step: Int = 1,
        unit: String? = nil,
        formatValue: ((Int) -> String)? = nil,
        size: ValueStepperSize = .md,
        label: String
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.formatValue = formatValue
        self.size = size
        self.label = label
    }

    private var readout: String {
        if let formatValue { return formatValue(value) }
        guard let unit else { return "\(value)" }
        return "\(value) \(unit)"
    }

    private var canDecrement: Bool { value > range.lowerBound }
    private var canIncrement: Bool { value < range.upperBound }

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            AppButton(icon: "minus", accessibilityLabel: "Decrease", variant: .secondary, appearance: .soft, action: decrement)
                .disabled(!canDecrement)
            Text(readout)
                .textStyle(.sansLg, numeric: true, lines: 1, align: .center)
                .frame(minWidth: size.readoutWidth)
            AppButton(icon: "plus", accessibilityLabel: "Increase", variant: .secondary, appearance: .soft, action: increment)
                .disabled(!canIncrement)
        }
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(readout)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private func increment() { value = min(value + step, range.upperBound) }
    private func decrement() { value = max(value - step, range.lowerBound) }
}

private struct ValueStepperGallery: View {
    @State private var servings = 4

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            SectionCard("Servings") {
                HStack {
                    Text("Portions the recipe makes").textStyle(.sansSm, tone: .tertiary)
                    Spacer(minLength: DS.Spacing.s3)
                    ValueStepper(value: $servings, in: 1...12, label: "Servings")
                }
            }
            ValueStepper(value: $servings, in: 1...12, unit: "servings", label: "Servings")
            ValueStepper(value: $servings, in: 1...12, size: .sm, label: "Servings")
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { ValueStepperGallery() }
#Preview("Dark") { ValueStepperGallery().preferredColorScheme(.dark) }
