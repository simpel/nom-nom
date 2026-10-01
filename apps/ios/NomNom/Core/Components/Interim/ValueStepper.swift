// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// Minus / value / plus: two AppButton `secondary soft sm` icon-only buttons around
/// a `serif-sm` tabular value, with an optional title and caption on the leading
/// side. VoiceOver gets one adjustable element.
///
/// ```swift
/// ValueStepper("Servings", value: $serves, in: 1...30, caption: "Portions the recipe makes")
/// // Optional value: stepping below the range clears it, plus from empty starts at `startValue`.
/// ValueStepper("Servings", optionalValue: $serves, in: 1...30, startValue: 4)
/// ```
struct ValueStepper: View {
    let title: String?
    private let value: Binding<Int?>
    var range: ClosedRange<Int>
    var step: Int
    var caption: String?
    private let allowsUnset: Bool
    private let startValue: Int
    private let format: (Int) -> String

    init(
        _ title: String? = nil,
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        step: Int = 1,
        caption: String? = nil,
        format: @escaping (Int) -> String = { "\($0)" }
    ) {
        self.title = title
        self.value = Binding(get: { value.wrappedValue }, set: { value.wrappedValue = $0 ?? range.lowerBound })
        self.range = range
        self.step = step
        self.caption = caption
        self.allowsUnset = false
        self.startValue = range.lowerBound
        self.format = format
    }

    init(
        _ title: String? = nil,
        optionalValue: Binding<Int?>,
        in range: ClosedRange<Int>,
        step: Int = 1,
        startValue: Int? = nil,
        caption: String? = nil,
        format: @escaping (Int) -> String = { "\($0)" }
    ) {
        self.title = title
        self.value = optionalValue
        self.range = range
        self.step = step
        self.caption = caption
        self.allowsUnset = true
        self.startValue = startValue ?? range.lowerBound
        self.format = format
    }

    private var current: Int? { value.wrappedValue }
    private var canDecrement: Bool {
        guard let current else { return false }
        return allowsUnset || current > range.lowerBound
    }
    private var canIncrement: Bool { (current ?? range.lowerBound) < range.upperBound || current == nil }
    private var valueText: String { current.map(format) ?? "\u{2014}" }

    var body: some View {
        HStack(spacing: DS.Spacing.s3) {
            if title != nil || caption != nil {
                VStack(alignment: .leading, spacing: DS.Spacing.s0_5) {
                    if let title { Text(title).textStyle(.sansMd) }
                    if let caption { Text(caption).textStyle(.sansSm, tone: .tertiary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: DS.Spacing.s2) {
                AppButton(icon: "minus", accessibilityLabel: "Decrease", variant: .secondary, appearance: .soft, size: .sm, action: decrement)
                    .disabled(!canDecrement)
                Text(valueText)
                    .textStyle(.serifSm, tone: current == nil ? .tertiary : .primary, numeric: true)
                    .frame(minWidth: DS.Spacing.s10)
                    .multilineTextAlignment(.center)
                AppButton(icon: "plus", accessibilityLabel: "Increase", variant: .secondary, appearance: .soft, size: .sm, action: increment)
                    .disabled(!canIncrement)
            }
        }
        .sensoryFeedback(.selection, trigger: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title ?? "Value")
        .accessibilityValue(current == nil ? "Not set" : valueText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private func increment() {
        guard let current else {
            value.wrappedValue = startValue
            return
        }
        value.wrappedValue = min(current + step, range.upperBound)
    }

    private func decrement() {
        guard let current else { return }
        if current - step < range.lowerBound {
            value.wrappedValue = allowsUnset ? nil : range.lowerBound
        } else {
            value.wrappedValue = current - step
        }
    }
}

private struct ValueStepperGallery: View {
    @State private var count = 4
    @State private var serves: Int? = nil

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            Card {
                ValueStepper("Servings", value: $count, in: 1...30, caption: "Portions the recipe makes")
            }
            Card {
                ValueStepper("Servings", optionalValue: $serves, in: 1...30, startValue: 4, caption: "Tap plus to set")
            }
            ValueStepper(value: $count, in: 0...10, step: 2) { "\($0) min" }
        }
        .padding(DS.Spacing.gutter)
        .background(DS.Color.bg)
    }
}

#Preview("Light") { ValueStepperGallery() }
#Preview("Dark") { ValueStepperGallery().preferredColorScheme(.dark) }
