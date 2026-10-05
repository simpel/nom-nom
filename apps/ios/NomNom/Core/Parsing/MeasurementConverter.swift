import Foundation

/// Converts a recipe amount (a free-text quantity and its unit) between metric and
/// US customary, the one place that does it.
///
/// Weight and volume only. Counts and other words ("2 cloves", "a pinch", "to taste") and
/// quantities it cannot read are returned unchanged, so converting never invents an
/// amount. Teaspoons and tablespoons stay as written in both systems; they are not
/// converted to millilitres.
///
/// ```swift
/// MeasurementConverter.convert(quantity: "500", unit: "g", to: .imperial)   // ("1.1", "lb")
/// MeasurementConverter.convert(quantity: "2", unit: "cups", to: .metric)    // ("475", "ml")
/// ```
enum MeasurementConverter {

    typealias Amount = (quantity: String, unit: String)

    private enum Unit {
        case gram, kilogram, millilitre, litre, decilitre, centilitre
        case ounce, pound, fluidOunce, cup, pint, quart

        var isMetric: Bool {
            switch self {
            case .gram, .kilogram, .millilitre, .litre, .decilitre, .centilitre: return true
            default: return false
            }
        }

        init?(_ text: String) {
            let key = text.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespaces))
            switch key {
            case "g", "gram", "grams", "gr": self = .gram
            case "kg", "kilo", "kilos", "kilogram", "kilograms": self = .kilogram
            case "ml", "milliliter", "milliliters", "millilitre", "millilitres": self = .millilitre
            case "l", "liter", "liters", "litre", "litres": self = .litre
            case "dl", "deciliter", "deciliters", "decilitre", "decilitres": self = .decilitre
            case "cl", "centiliter", "centiliters", "centilitre", "centilitres": self = .centilitre
            case "oz", "ounce", "ounces": self = .ounce
            case "lb", "lbs", "pound", "pounds": self = .pound
            case "fl oz", "fl. oz", "floz", "fluid ounce", "fluid ounces": self = .fluidOunce
            case "cup", "cups": self = .cup
            case "pt", "pint", "pints": self = .pint
            case "qt", "quart", "quarts": self = .quart
            default: return nil
            }
        }

        /// Grams or millilitres per unit, and which of the two it measures.
        var base: (factor: Double, isWeight: Bool) {
            switch self {
            case .gram: return (1, true)
            case .kilogram: return (1000, true)
            case .ounce: return (28.3495, true)
            case .pound: return (453.592, true)
            case .millilitre: return (1, false)
            case .centilitre: return (10, false)
            case .decilitre: return (100, false)
            case .litre: return (1000, false)
            case .fluidOunce: return (29.5735, false)
            case .cup: return (236.588, false)
            case .pint: return (473.176, false)
            case .quart: return (946.353, false)
            }
        }
    }

    static func convert(quantity: String, unit: String, to system: UnitSystem) -> Amount {
        let text = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        let measurement = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let source = Unit(measurement),
              source.isMetric == (system == .imperial),
              let parsed = QuantityScaler.parseLeading(text),
              parsed.rest.trimmingCharacters(in: .whitespaces).isEmpty,
              parsed.value > 0
        else { return (text, measurement) }

        let (factor, isWeight) = source.base
        let amount = parsed.value * factor
        return system == .imperial ? imperial(amount, isWeight: isWeight) : metric(amount, isWeight: isWeight)
    }

    // MARK: - Targets

    private static func metric(_ amount: Double, isWeight: Bool) -> Amount {
        if isWeight {
            return amount >= 1000 ? (decimal(amount / 1000), "kg") : (whole(amount), "g")
        }
        return amount >= 1000 ? (decimal(amount / 1000), "l") : (whole(amount), "ml")
    }

    private static func imperial(_ amount: Double, isWeight: Bool) -> Amount {
        if isWeight {
            let pounds = amount / Unit.pound.base.factor
            if pounds >= 1 { return (decimal(pounds), "lb") }
            return (QuantityScaler.format(amount / Unit.ounce.base.factor), "oz")
        }
        let cups = amount / Unit.cup.base.factor
        if cups >= 0.25 { return (QuantityScaler.format(cups), cups > 1 ? "cups" : "cup") }
        return (QuantityScaler.format(amount / Unit.fluidOunce.base.factor), "fl oz")
    }

    // MARK: - Rounding

    /// Whole units, in fives from 100 up so "453.6 g" reads "455 g".
    private static func whole(_ value: Double) -> String {
        let rounded = value >= 100 ? (value / 5).rounded() * 5 : value.rounded()
        return String(Int(max(rounded, 1)))
    }

    private static func decimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
