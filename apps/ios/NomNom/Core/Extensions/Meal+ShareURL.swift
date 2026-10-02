import Foundation

extension Meal {
    /// A universal link that opens this meal (DeepLink parses `/meal?id=`).
    var shareURL: URL {
        URL(string: "https://www.nomnom.casa/meal?id=\(id.uuidString)")!
    }
}
