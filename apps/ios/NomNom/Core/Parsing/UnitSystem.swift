import Foundation

/// Which measurement system amounts are shown in. One choice per person, kept on their
/// profile (`profiles.unit_system`): read `store.unitSystem`, change it with
/// `store.setUnitSystem(_:)`, and every screen that shows an amount follows.
enum UnitSystem: String, CaseIterable {
    case metric
    case imperial

    /// Imperial for a US locale, metric everywhere else, until the person chooses.
    static var deviceDefault: UnitSystem {
        Locale.current.measurementSystem == .us ? .imperial : .metric
    }

    var isImperial: Bool {
        get { self == .imperial }
        set { self = newValue ? .imperial : .metric }
    }
}
