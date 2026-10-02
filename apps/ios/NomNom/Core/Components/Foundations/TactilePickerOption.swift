import SwiftUI

/// A selectable option with a label, optional icon and description, and an accent
/// tint. Domain enums (`Reaction`, `EffortLevel`, `RotationGoal`) conform so the
/// OptionCell selectors can read them uniformly.
public protocol TactilePickerOption: Identifiable, Equatable {
    var label: String { get }
    var icon: String? { get }
    var description: String? { get }
    var tint: Color { get }
}

public extension TactilePickerOption {
    var icon: String? { nil }
    var description: String? { nil }
    var tint: Color { DS.Color.primary }
}
