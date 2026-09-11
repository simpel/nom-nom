import Foundation

extension Int {
    /// Returns the number formatted as an ordinal string (e.g., 1st, 2nd, 3rd, 4th)
    var ordinalString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
