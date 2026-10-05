import Foundation

extension RecipeIngredient {
    /// The amount to show: the quantity scaled by `factor` (servings), then expressed in
    /// `units`. "500 g" at ×2 in imperial reads "2.2 lb".
    func displayAmount(scaledBy factor: Double = 1, in units: UnitSystem) -> String {
        let scaled = QuantityScaler.scale(trimmedQuantity, by: factor)
        let converted = MeasurementConverter.convert(quantity: scaled, unit: trimmedMeasurement, to: units)
        return [converted.quantity, converted.unit].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
