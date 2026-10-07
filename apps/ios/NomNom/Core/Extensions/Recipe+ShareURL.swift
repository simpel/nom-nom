import Foundation

extension Recipe {
    /// A universal link that opens this recipe (DeepLink parses `/recipe?id=`).
    var shareURL: URL {
        URL(string: "https://www.nomnom.casa/recipe?id=\(id.uuidString)")!
    }
}
