import Foundation

/// "Make it land next time" for one party meal, from the `suggest-recipe-tweaks` edge
/// function (Nom Nom Pro): what most explains the score and up to three changes.
struct RecipeTweaks: Hashable, Decodable {
    struct Tip: Identifiable, Hashable, Decodable {
        let title: String
        let reason: String
        /// Expected rise in the table's score, display points (1–40).
        let lift: Int

        var id: String { title }
    }

    /// "Heat sank it". Empty when the model gave none.
    let headline: String
    let summary: String
    let tips: [Tip]

    /// The tips as a party recipe note: one condensed bullet per tip, the change alone
    /// ("• Halve the chilli"). The reason stays on the score sheet.
    var noteLines: [String] {
        BulletList.lines(tips.map(\.title))
    }
}
