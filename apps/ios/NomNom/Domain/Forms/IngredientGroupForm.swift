import Foundation

/// One ingredient group in IngredientGroupSheet: its name and where it sits among the
/// recipe's groups (0 = first).
struct IngredientGroupForm: SheetForm {
    var group: IngredientGroup
    var position: Int
}
